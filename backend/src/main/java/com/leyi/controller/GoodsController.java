package com.leyi.controller;

import com.leyi.common.PageResult;
import com.leyi.common.Result;
import com.leyi.entity.Goods;
import com.leyi.exception.BusinessException;
import com.leyi.security.AuthGuard;
import com.leyi.service.CommentService;
import com.leyi.service.GoodsService;
import com.leyi.util.RequestValueParser;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/goods")
public class GoodsController {

    @Autowired
    private GoodsService goodsService;

    @Autowired
    private CommentService commentService;

    @Autowired
    private AuthGuard authGuard;

    @GetMapping("/list")
    public Result<?> list(
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "default") String sort,
            @RequestParam(required = false) Integer isOnSale,
            @RequestParam(defaultValue = "false") Boolean includeChildren,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        PageResult<Goods> result = goodsService.getList(categoryId, keyword, sort, isOnSale, includeChildren, pageNum, pageSize);
        return Result.success(result);
    }

    @GetMapping("/detail/{id}")
    public Result<?> detail(@PathVariable Long id) {
        Goods goods = goodsService.getById(id);
        if (goods == null) {
            return Result.error("商品不存在");
        }
        Map<String, Object> result = new HashMap<>();
        result.put("goods", goods);
        result.put("comments", commentService.getByGoodsId(id));
        result.put("avgRating", commentService.getAverageRating(id));
        result.put("commentCount", commentService.getCount(id));
        return Result.success(result);
    }

    @GetMapping("/barcode/{barCode}")
    public Result<?> getByBarCode(HttpServletRequest request, @PathVariable String barCode) {
        authGuard.requireAdmin(request);
        return Result.success(goodsService.getByBarCode(barCode));
    }

    @PostMapping("/add")
    public Result<?> add(HttpServletRequest request, @RequestBody Map<String, Object> params) {
        authGuard.requireManager(request);
        Goods goods = buildGoods(params, false);
        goodsService.add(goods, parseImageUrls(params.get("imageUrls")));
        return Result.success();
    }

    @PutMapping("/update")
    public Result<?> update(HttpServletRequest request, @RequestBody Map<String, Object> params) {
        authGuard.requireManager(request);
        Goods goods = buildGoods(params, true);
        goodsService.update(goods, parseImageUrls(params.get("imageUrls")));
        return Result.success();
    }

    @PutMapping("/sale/{id}")
    public Result<?> updateSaleStatus(HttpServletRequest request, @PathVariable Long id, @RequestParam Integer isOnSale) {
        authGuard.requireManager(request);
        authGuard.requireBinaryFlag(isOnSale, "上架状态");
        goodsService.updateSaleStatus(id, isOnSale);
        return Result.success();
    }

    @DeleteMapping("/delete/{id}")
    public Result<?> delete(HttpServletRequest request, @PathVariable Long id) {
        authGuard.requireManager(request);
        goodsService.delete(id);
        return Result.success();
    }

    private Goods buildGoods(Map<String, Object> params, boolean requireId) {
        Goods goods = new Goods();
        if (requireId) {
            goods.setId(RequestValueParser.requireLong(params, "id", "商品ID"));
        }
        goods.setCategoryId(RequestValueParser.requireLong(params, "categoryId", "分类"));
        goods.setName(RequestValueParser.requireString(params, "name", "商品名称"));
        goods.setPrice(RequestValueParser.requireBigDecimal(params, "price", "价格"));
        goods.setStock(RequestValueParser.requireInteger(params, "stock", "库存"));
        goods.setSafetyStock(RequestValueParser.getInteger(params, "safetyStock", 10, "安全库存"));
        goods.setBarCode(defaultString(RequestValueParser.getTrimmedString(params, "barCode")));
        goods.setImageUrl(defaultString(RequestValueParser.getTrimmedString(params, "imageUrl")));
        goods.setDescription(defaultString(RequestValueParser.getTrimmedString(params, "description")));
        goods.setPromotionTag(defaultString(RequestValueParser.getTrimmedString(params, "promotionTag")));

        Integer isOnSale = RequestValueParser.getInteger(params, "isOnSale", 1, "上架状态");
        authGuard.requireBinaryFlag(isOnSale, "上架状态");
        goods.setIsOnSale(isOnSale);

        String expireDate = RequestValueParser.getTrimmedString(params, "expireDate");
        if (expireDate != null && !expireDate.isEmpty()) {
            try {
                goods.setExpireDate(LocalDate.parse(expireDate));
            } catch (DateTimeParseException e) {
                throw new BusinessException(400, "保质期格式错误");
            }
        }
        return goods;
    }

    private List<String> parseImageUrls(Object value) {
        if (value == null) {
            return null;
        }
        if (!(value instanceof List<?> rawList)) {
            throw new BusinessException(400, "图片列表格式错误");
        }
        List<String> imageUrls = new ArrayList<>();
        for (Object item : rawList) {
            if (item == null) {
                continue;
            }
            String text = item.toString().trim();
            if (!text.isEmpty()) {
                imageUrls.add(text);
            }
        }
        return imageUrls;
    }

    private String defaultString(String value) {
        return value == null ? "" : value;
    }
}
