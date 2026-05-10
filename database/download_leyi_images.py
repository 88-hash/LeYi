#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import re
import shutil
import sys
import time
from pathlib import Path
from typing import Iterable
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
SEED_PATH = SCRIPT_DIR / "leyi_catalog_seed.json"
SQL_PATH = SCRIPT_DIR / "insert_leyi_test_data.sql"
MANIFEST_JSON_PATH = SCRIPT_DIR / "leyi_image_manifest.json"
MANIFEST_CSV_PATH = SCRIPT_DIR / "leyi_image_manifest.csv"
MISSING_REPORT_PATH = SCRIPT_DIR / "leyi_missing_images.json"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "backend" / "uploads" / "goods"

HTTP_TIMEOUT = 6
USER_AGENT = "LeYiSnackSeedBot/2.0 (+http://localhost)"
VALID_IMAGE_SUFFIXES = (".jpg", ".jpeg", ".png", ".webp")

PLACEHOLDER_PATTERN = re.compile(r"\?{2,}|�")
TOKEN_PATTERN = re.compile(r"[a-z0-9]+|[\u4e00-\u9fff]{2,}")

BASE_NEGATIVE_TOKENS = {
    "soup",
    "broth",
    "bouillon",
    "potage",
    "seasoning",
    "condiment",
    "ham",
    "jambon",
    "charcuterie",
    "tuna",
    "thon",
    "vegetable",
    "vegetables",
    "legumes",
    "chicoree",
    "detergent",
    "toothpaste",
    "dog",
    "cat",
}

STOP_TOKENS = {
    "and",
    "the",
    "with",
    "for",
    "snack",
    "snacks",
    "package",
    "pack",
    "drink",
    "bottle",
    "original",
    "classic",
    "flavor",
    "flavours",
    "flavour",
    "s",
    "x",
}


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def has_local_asset(path: Path) -> bool:
    return path.is_file() and path.stat().st_size > 0


def tokenize_text(text: str) -> list[str]:
    return TOKEN_PATTERN.findall((text or "").lower())


def unique_queries(values: Iterable[str]) -> list[str]:
    result: list[str] = []
    seen: set[str] = set()
    for value in values:
        cleaned = " ".join(str(value or "").strip().split())
        if cleaned and cleaned not in seen:
            seen.add(cleaned)
            result.append(cleaned)
    return result


def looks_like_image(url: str) -> bool:
    clean_url = url.lower().split("?", 1)[0]
    return clean_url.endswith(VALID_IMAGE_SUFFIXES)


def contains_placeholder_text(value: str | None) -> bool:
    text = str(value or "").strip()
    if not text:
        return True
    return bool(PLACEHOLDER_PATTERN.search(text))


def validate_text_field(value: str | None, label: str) -> None:
    if contains_placeholder_text(value):
        raise ValueError(f"{label} contains placeholder or broken text: {value!r}")


def validate_seed(seed: dict) -> None:
    categories = seed.get("categories", [])
    products = seed.get("products", [])
    if len(categories) != 8:
        raise ValueError(f"Expected 8 top categories, found {len(categories)}")
    if len(products) != 100:
        raise ValueError(f"Expected 100 products, found {len(products)}")

    child_ids: set[int] = set()
    top_ids: set[int] = set()

    for category in categories:
        top_ids.add(int(category["id"]))
        validate_text_field(category.get("name"), f"category[{category['id']}].name")
        for child in category.get("children", []):
            child_ids.add(int(child["id"]))
            validate_text_field(child.get("name"), f"category[{child['id']}].name")

    seen_goods: set[int] = set()
    for product in products:
        goods_id = int(product["id"])
        if goods_id in seen_goods:
            raise ValueError(f"Duplicate goods id: {goods_id}")
        seen_goods.add(goods_id)
        if int(product["category_id"]) not in child_ids:
            raise ValueError(f"goods[{goods_id}] points to unknown child category")

        for field in (
            "category_name",
            "parent_category_name",
            "brand",
            "short_name",
            "name",
            "description",
        ):
            validate_text_field(product.get(field), f"goods[{goods_id}].{field}")

        if product.get("promotion_tag"):
            validate_text_field(product.get("promotion_tag"), f"goods[{goods_id}].promotion_tag")

        for index, term in enumerate(product.get("search_terms", [])):
            validate_text_field(term, f"goods[{goods_id}].search_terms[{index}]")

        validate_text_field(product.get("fallback_terms"), f"goods[{goods_id}].fallback_terms")


def load_seed(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as file:
        seed = json.load(file)
    validate_seed(seed)
    return seed


def http_get_json(url: str) -> dict | None:
    request = Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "application/json",
        },
    )
    try:
        with urlopen(request, timeout=HTTP_TIMEOUT) as response:
            return json.loads(response.read().decode("utf-8"))
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError):
        return None


def download_binary(url: str) -> bytes | None:
    request = Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "image/jpeg,image/png,image/webp,image/*;q=0.8,*/*;q=0.5",
        },
    )
    try:
        with urlopen(request, timeout=HTTP_TIMEOUT) as response:
            return response.read()
    except (HTTPError, URLError, TimeoutError):
        return None


def make_candidate(source_name: str, url: str, text: str) -> dict:
    return {
        "source_name": source_name,
        "url": url,
        "text": " ".join(str(text or "").split()),
    }


def dedupe_candidates(candidates: Iterable[dict]) -> list[dict]:
    result: list[dict] = []
    seen: set[str] = set()
    for candidate in candidates:
        url = candidate["url"]
        if url and url not in seen:
            seen.add(url)
            result.append(candidate)
    return result


def collect_open_food_facts_candidates(product: dict, query: str) -> list[dict]:
    params = urlencode(
        {
            "search_terms": query,
            "search_simple": 1,
            "action": "process",
            "json": 1,
            "page_size": 5,
        }
    )
    payload = http_get_json(f"https://world.openfoodfacts.org/cgi/search.pl?{params}")
    if not payload:
        return []

    candidates: list[dict] = []
    for item in payload.get("products", []):
        match_text = " ".join(
            [
                item.get("product_name") or "",
                item.get("product_name_en") or "",
                item.get("product_name_zh") or "",
                item.get("brands") or "",
                item.get("generic_name") or "",
                item.get("generic_name_en") or "",
            ]
        )
        for key in ("image_front_url", "image_url", "image_front_small_url"):
            url = (item.get(key) or "").strip()
            if url and looks_like_image(url):
                candidates.append(make_candidate("open_food_facts", url, match_text))
    return dedupe_candidates(candidates)


def collect_openverse_candidates(query: str) -> list[dict]:
    params = urlencode(
        {
            "q": query,
            "page_size": 5,
            "license_type": "commercial",
        }
    )
    payload = http_get_json(f"https://api.openverse.org/v1/images/?{params}")
    if not payload:
        return []

    candidates: list[dict] = []
    for item in payload.get("results", []):
        url = (item.get("url") or "").strip()
        if not url or not looks_like_image(url):
            continue
        text = " ".join(
            [
                item.get("title") or "",
                item.get("creator") or "",
                " ".join((tag.get("name") or "") for tag in item.get("tags", [])),
            ]
        )
        candidates.append(make_candidate("openverse", url, text))
    return dedupe_candidates(candidates)


def collect_wikimedia_candidates(query: str) -> list[dict]:
    params = urlencode(
        {
            "action": "query",
            "generator": "search",
            "gsrsearch": query,
            "gsrnamespace": 6,
            "gsrlimit": 5,
            "prop": "imageinfo",
            "iiprop": "url",
            "iiurlwidth": 1600,
            "format": "json",
            "formatversion": 2,
        }
    )
    payload = http_get_json(f"https://commons.wikimedia.org/w/api.php?{params}")
    if not payload:
        return []

    candidates: list[dict] = []
    for page in payload.get("query", {}).get("pages", []):
        page_title = page.get("title") or ""
        for image_info in page.get("imageinfo", []):
            url = (image_info.get("url") or "").strip()
            if url and looks_like_image(url):
                candidates.append(make_candidate("wikimedia", url, page_title))
    return dedupe_candidates(candidates)


def build_search_queries(product: dict) -> list[str]:
    return unique_queries((product.get("search_terms", []) or [])[:2])


def build_fallback_queries(product: dict) -> list[str]:
    return unique_queries([product.get("fallback_terms", "")])


def normalized_terms(values: Iterable[str]) -> set[str]:
    return {
        token
        for value in values
        for token in tokenize_text(str(value or ""))
        if token and token not in STOP_TOKENS
    }


def candidate_score(product: dict, candidate: dict, fallback_used: bool) -> int:
    tokens = set(tokenize_text(candidate.get("text", "")))
    if not tokens:
        return -1

    brand_terms = normalized_terms(product.get("image_brand_terms", []))
    core_terms = normalized_terms(product.get("image_core_terms", []))
    fallback_terms = normalized_terms([product.get("fallback_terms", "")])
    negative_terms = BASE_NEGATIVE_TOKENS | normalized_terms(product.get("image_exclude_terms", []))

    if tokens & negative_terms:
        return -1

    brand_hits = len(tokens & brand_terms)
    core_hits = len(tokens & core_terms)
    fallback_hits = len(tokens & fallback_terms)

    source_name = candidate["source_name"]
    if fallback_used:
        if core_hits == 0 and fallback_hits < 2:
            return -1
    elif source_name == "open_food_facts":
        if brand_terms and brand_hits == 0 and core_hits < 2:
            return -1
        if core_hits == 0 and fallback_hits == 0:
            return -1
    else:
        if brand_terms and brand_hits == 0 and core_hits == 0:
            return -1
        if core_hits == 0 and fallback_hits == 0:
            return -1

    return brand_hits * 20 + core_hits * 12 + fallback_hits * 4 + (
        5 if source_name == "open_food_facts" else 0
    )


def select_candidates(product: dict, candidates: list[dict], fallback_used: bool) -> list[dict]:
    scored: list[tuple[int, dict]] = []
    for candidate in candidates:
        score = candidate_score(product, candidate, fallback_used)
        if score >= 0:
            scored.append((score, candidate))
    scored.sort(key=lambda item: item[0], reverse=True)
    return [candidate for _, candidate in scored]


def try_candidates(
    product: dict,
    candidates: list[dict],
    destination: Path,
    fallback_used: bool,
    override_used: bool,
    used_source_urls: set[str],
) -> dict | None:
    for candidate in select_candidates(product, candidates, fallback_used):
        if candidate["url"] in used_source_urls:
            continue
        payload = download_binary(candidate["url"])
        if not payload:
            continue
        ensure_parent(destination)
        destination.write_bytes(payload)
        return {
            "goods_id": product["id"],
            "goods_name": product["name"],
            "file_name": destination.name,
            "image_url": product["image_url"],
            "source_name": candidate["source_name"],
            "source_url": candidate["url"],
            "query": candidate.get("text", ""),
            "fallback_used": fallback_used,
            "override_used": override_used,
            "status": "downloaded",
        }
    return None


def download_image_for_product(product: dict, destination: Path, used_source_urls: set[str]) -> dict:
    override_urls = [
        make_candidate("override", url, product["name"])
        for url in product.get("image_override_urls", [])
        if url
    ]
    if override_urls:
        result = try_candidates(
            product=product,
            candidates=override_urls,
            destination=destination,
            fallback_used=False,
            override_used=True,
            used_source_urls=used_source_urls,
        )
        if result:
            return result

    source_groups = [
        (
            "open_food_facts",
            build_search_queries(product),
            lambda query: collect_open_food_facts_candidates(product, query),
            False,
        ),
        ("openverse", build_search_queries(product), collect_openverse_candidates, False),
        ("wikimedia", build_search_queries(product), collect_wikimedia_candidates, False),
        ("openverse", build_fallback_queries(product), collect_openverse_candidates, True),
        ("wikimedia", build_fallback_queries(product), collect_wikimedia_candidates, True),
    ]

    for _, queries, collector, fallback_used in source_groups:
        for query in queries:
            candidates = collector(query)
            if not candidates:
                continue
            result = try_candidates(
                product=product,
                candidates=candidates,
                destination=destination,
                fallback_used=fallback_used,
                override_used=False,
                used_source_urls=used_source_urls,
            )
            if result:
                result["query"] = query
                return result

    return {
        "goods_id": product["id"],
        "goods_name": product["name"],
        "file_name": destination.name,
        "image_url": product["image_url"],
        "source_name": "",
        "source_url": "",
        "query": "",
        "fallback_used": True,
        "override_used": False,
        "status": "missing",
    }


def write_manifest(records: list[dict], json_path: Path, csv_path: Path) -> None:
    ensure_parent(json_path)
    json_path.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")

    ensure_parent(csv_path)
    with csv_path.open("w", encoding="utf-8-sig", newline="") as file:
        writer = csv.DictWriter(
            file,
            fieldnames=[
                "goods_id",
                "goods_name",
                "file_name",
                "image_url",
                "source_name",
                "source_url",
                "query",
                "fallback_used",
                "override_used",
                "local_file_exists",
                "effective_image_url",
                "status",
            ],
        )
        writer.writeheader()
        writer.writerows(records)


def read_manifest(json_path: Path) -> list[dict]:
    if not json_path.exists():
        return []
    return json.loads(json_path.read_text(encoding="utf-8"))


def normalize_manifest(records: list[dict]) -> list[dict]:
    return sorted(records, key=lambda row: int(row["goods_id"]))


def build_manifest_row(product: dict, existing: dict | None = None) -> dict:
    row = {
        "goods_id": product["id"],
        "goods_name": product["name"],
        "file_name": product["file_name"],
        "image_url": product["image_url"],
        "source_name": "",
        "source_url": "",
        "query": "",
        "fallback_used": False,
        "override_used": False,
        "local_file_exists": False,
        "effective_image_url": "",
        "status": "missing",
    }
    if existing:
        row.update(existing)
    return row


def finalize_manifest(products: list[dict], manifest_map: dict[int, dict], output_dir: Path) -> list[dict]:
    rows: list[dict] = []
    for product in products:
        goods_id = int(product["id"])
        row = build_manifest_row(product, manifest_map.get(goods_id))
        local_file = output_dir / row["file_name"]
        file_exists = has_local_asset(local_file)
        row["local_file_exists"] = file_exists
        row["effective_image_url"] = product["image_url"] if file_exists else ""
        if not file_exists and row["status"] == "downloaded":
            row["status"] = "missing"
        rows.append(row)
    return normalize_manifest(rows)


def write_missing_report(records: list[dict], output_path: Path) -> list[dict]:
    missing = [
        {
            "goods_id": row["goods_id"],
            "goods_name": row["goods_name"],
            "file_name": row["file_name"],
            "expected_image_url": row["image_url"],
            "recommended_action": "Upload a local image from the admin goods editor.",
        }
        for row in records
        if not row.get("effective_image_url")
    ]
    ensure_parent(output_path)
    output_path.write_text(json.dumps(missing, ensure_ascii=False, indent=2), encoding="utf-8")
    return missing


def backfill_missing_with_local_assets(records: list[dict], products: list[dict], output_dir: Path) -> None:
    product_map = {product["id"]: product for product in products}
    by_category: dict[int, list[dict]] = {}
    by_parent: dict[str, list[dict]] = {}

    for record in records:
        if record["status"] != "downloaded":
            continue
        product = product_map[record["goods_id"]]
        by_category.setdefault(int(product["category_id"]), []).append(record)
        by_parent.setdefault(str(product["parent_category_key"]), []).append(record)

    for record in records:
        if record["status"] != "missing":
            continue

        product = product_map[record["goods_id"]]
        category_candidates = by_category.get(int(product["category_id"]), [])
        parent_candidates = by_parent.get(str(product["parent_category_key"]), [])
        source_record = None
        source_name = ""

        if category_candidates:
            source_record = category_candidates[-1]
            source_name = "local_category_fallback"
        elif parent_candidates:
            source_record = parent_candidates[-1]
            source_name = "local_parent_fallback"

        if not source_record:
            continue

        source_file = output_dir / source_record["file_name"]
        target_file = output_dir / record["file_name"]
        if not source_file.exists():
            continue

        shutil.copyfile(source_file, target_file)
        record["status"] = "downloaded"
        record["source_name"] = source_name
        record["source_url"] = source_record["image_url"]
        record["query"] = f"local:{source_record['goods_id']}"
        record["fallback_used"] = True
        record["override_used"] = False
        by_category.setdefault(int(product["category_id"]), []).append(record)
        by_parent.setdefault(str(product["parent_category_key"]), []).append(record)


def sql_string(value: str | None) -> str:
    if value is None:
        return "NULL"
    escaped = value.replace("\\", "\\\\").replace("'", "''")
    return f"'{escaped}'"


def sql_number(value: int | float) -> str:
    if isinstance(value, int):
        return str(value)
    return f"{value:.2f}"


def generate_sql(seed: dict, manifest_rows: list[dict], output_path: Path) -> None:
    top_categories = seed.get("categories", [])
    child_categories = [child for category in top_categories for child in category.get("children", [])]
    products = seed.get("products", [])
    image_url_map = {
        int(row["goods_id"]): row.get("effective_image_url", "")
        for row in manifest_rows
    }

    category_rows = [
        f"({category['id']}, 0, {sql_string(category['name'])}, {category['sort']})"
        for category in top_categories
    ]
    category_rows.extend(
        f"({child['id']}, {category['id']}, {sql_string(child['name'])}, {child['sort']})"
        for category in top_categories
        for child in category.get("children", [])
    )

    goods_rows = []
    for product in products:
        effective_image_url = image_url_map.get(int(product["id"]), "")
        goods_rows.append(
            "("
            f"{product['id']}, "
            f"{product['category_id']}, "
            f"{sql_string(product['name'])}, "
            f"{sql_number(product['price'])}, "
            f"{product['stock']}, "
            f"{product['safety_stock']}, "
            f"{sql_string(product['bar_code'])}, "
            f"{sql_string(effective_image_url)}, "
            f"{sql_string(product['description'])}, "
            f"{sql_string(product['promotion_tag'])}, "
            f"{product.get('is_on_sale', 1)}, "
            "0, "
            f"{sql_string(product['expire_date'])}"
            ")"
        )

    goods_image_rows = [
        f"({product['id']}, {sql_string(image_url_map.get(int(product['id']), ''))}, 1)"
        for product in products
        if image_url_map.get(int(product["id"]), "")
    ]

    next_category_id = max(child["id"] for child in child_categories) + 1 if child_categories else 1
    next_goods_id = max(product["id"] for product in products) + 1 if products else 1
    next_goods_image_id = len(goods_image_rows) + 1

    lines = [
        "-- LeYi Snack Shop rebuilt catalog test data",
        "-- Generated from database/rebuild_leyi_catalog_seed.py and leyi_catalog_seed.json",
        "",
        "USE leyi_snack;",
        "",
        "SET FOREIGN_KEY_CHECKS = 0;",
        "",
        "DELETE FROM `verify_log`;",
        "DELETE FROM `comment`;",
        "DELETE FROM `order_item`;",
        "DELETE FROM `order`;",
        "DELETE FROM `cart`;",
        "DELETE FROM `goods_image`;",
        "DELETE FROM `goods`;",
        "DELETE FROM `category`;",
        "",
        "ALTER TABLE `category` AUTO_INCREMENT = 1;",
        "ALTER TABLE `goods` AUTO_INCREMENT = 1;",
        "ALTER TABLE `goods_image` AUTO_INCREMENT = 1;",
        "",
        "INSERT INTO `category` (`id`, `parent_id`, `name`, `sort`) VALUES",
        "  " + ",\n  ".join(category_rows) + ";",
        "",
        "INSERT INTO `goods` (`id`, `category_id`, `name`, `price`, `stock`, `safety_stock`, `bar_code`, `image_url`, `description`, `promotion_tag`, `is_on_sale`, `is_deleted`, `expire_date`) VALUES",
        "  " + ",\n  ".join(goods_rows) + ";",
        "",
        f"ALTER TABLE `category` AUTO_INCREMENT = {next_category_id};",
        f"ALTER TABLE `goods` AUTO_INCREMENT = {next_goods_id};",
        f"ALTER TABLE `goods_image` AUTO_INCREMENT = {next_goods_image_id};",
        "",
        "SET FOREIGN_KEY_CHECKS = 1;",
        "",
    ]

    if goods_image_rows:
        lines[lines.index(f"ALTER TABLE `category` AUTO_INCREMENT = {next_category_id};"):lines.index(f"ALTER TABLE `category` AUTO_INCREMENT = {next_category_id};")] = [
            "INSERT INTO `goods_image` (`goods_id`, `image_url`, `sort`) VALUES",
            "  " + ",\n  ".join(goods_image_rows) + ";",
            "",
        ]

    ensure_parent(output_path)
    output_path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate LeYi catalog SQL and download local goods images.")
    parser.add_argument("--seed", type=Path, default=SEED_PATH, help="Path to the catalog seed JSON file.")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR, help="Directory for downloaded goods images.")
    parser.add_argument("--manifest-json", type=Path, default=MANIFEST_JSON_PATH, help="Path to the JSON manifest output.")
    parser.add_argument("--manifest-csv", type=Path, default=MANIFEST_CSV_PATH, help="Path to the CSV manifest output.")
    parser.add_argument("--missing-report", type=Path, default=MISSING_REPORT_PATH, help="Path to the missing image report output.")
    parser.add_argument("--sql-output", type=Path, default=SQL_PATH, help="Path to the generated SQL output.")
    parser.add_argument("--limit", type=int, default=0, help="Optional limit for image downloads during testing.")
    parser.add_argument("--start-id", type=int, default=0, help="Only process goods with id greater than or equal to this value.")
    parser.add_argument("--goods-ids", type=str, default="", help="Comma separated goods ids to process.")
    parser.add_argument("--overwrite", action="store_true", help="Download images even if the local file already exists.")
    parser.add_argument("--sql-only", action="store_true", help="Only regenerate SQL and skip image downloads.")
    parser.add_argument("--download-only", action="store_true", help="Only download images and keep the existing SQL file untouched.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.sql_only and args.download_only:
        raise SystemExit("--sql-only and --download-only cannot be used together.")

    seed = load_seed(args.seed)
    manifest_map = {int(row["goods_id"]): row for row in read_manifest(args.manifest_json)}
    manifest_rows = finalize_manifest(seed["products"], manifest_map, args.output_dir)
    used_source_urls: set[str] = set()
    for row in manifest_rows:
        if row.get("source_url") and row["status"] == "downloaded":
            used_source_urls.add(row["source_url"])

    if not args.sql_only:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        products = seed["products"]
        if args.start_id:
            products = [product for product in products if int(product["id"]) >= args.start_id]
        if args.goods_ids:
            goods_ids = {
                int(part.strip())
                for part in args.goods_ids.split(",")
                if part.strip()
            }
            products = [product for product in products if int(product["id"]) in goods_ids]
        products = products[: args.limit or None]

        for index, product in enumerate(products, start=1):
            destination = args.output_dir / product["file_name"]
            if has_local_asset(destination) and not args.overwrite:
                manifest_map[int(product["id"])] = build_manifest_row(
                    product,
                    {
                        **manifest_map.get(int(product["id"]), {}),
                        "source_name": manifest_map.get(int(product["id"]), {}).get("source_name", "existing"),
                        "status": manifest_map.get(int(product["id"]), {}).get("status", "existing"),
                    },
                )
                manifest_rows = finalize_manifest(seed["products"], manifest_map, args.output_dir)
                write_manifest(manifest_rows, args.manifest_json, args.manifest_csv)
                continue

            result = download_image_for_product(product, destination, used_source_urls)
            manifest_map[int(product["id"])] = result
            if result["source_url"]:
                used_source_urls.add(result["source_url"])
            manifest_rows = finalize_manifest(seed["products"], manifest_map, args.output_dir)
            write_manifest(manifest_rows, args.manifest_json, args.manifest_csv)
            print(
                f"[{index:03d}/{len(products):03d}] "
                f"{product['name']} -> {result['status']} ({result['source_name'] or 'none'})"
            )
            time.sleep(0.12)

    manifest_rows = finalize_manifest(seed["products"], manifest_map, args.output_dir)
    backfill_missing_with_local_assets(manifest_rows, seed["products"], args.output_dir)
    manifest_map = {int(row["goods_id"]): row for row in manifest_rows}
    manifest_rows = finalize_manifest(seed["products"], manifest_map, args.output_dir)

    write_manifest(manifest_rows, args.manifest_json, args.manifest_csv)
    missing = write_missing_report(manifest_rows, args.missing_report)

    if not args.download_only:
        generate_sql(seed, manifest_rows, args.sql_output)
        print(f"[ok] SQL generated at {args.sql_output}")

    if missing:
        print(
            f"[warn] {len(missing)} images are still missing. See {args.missing_report}.",
            file=sys.stderr,
        )
    print(f"[ok] Image manifest written to {args.manifest_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
