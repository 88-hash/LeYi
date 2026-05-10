package com.leyi.service;

import com.leyi.common.PageResult;
import com.leyi.entity.Category;
import com.leyi.entity.Goods;
import com.leyi.entity.GoodsImage;
import com.leyi.mapper.CategoryMapper;
import com.leyi.mapper.GoodsImageMapper;
import com.leyi.mapper.GoodsMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class GoodsService {

    @Autowired
    private GoodsMapper goodsMapper;

    @Autowired
    private GoodsImageMapper goodsImageMapper;

    @Autowired
    private CategoryMapper categoryMapper;

    public PageResult<Goods> getList(Long categoryId, String keyword, String sort, Integer isOnSale, Boolean includeChildren, Integer pageNum, Integer pageSize) {
        int offset = (pageNum - 1) * pageSize;
        List<Long> categoryIds = null;

        if (Boolean.TRUE.equals(includeChildren) && categoryId != null) {
            List<Category> children = categoryMapper.findByParentId(categoryId);
            if (!children.isEmpty()) {
                categoryIds = children.stream()
                        .map(Category::getId)
                        .toList();
            }
        }

        List<Goods> list = goodsMapper.findList(categoryId, categoryIds, keyword, sort, isOnSale, offset, pageSize);
        Long total = goodsMapper.countList(categoryId, categoryIds, keyword, isOnSale);
        return PageResult.of(list, total, pageNum, pageSize);
    }

    public Goods getById(Long id) {
        Goods goods = goodsMapper.findById(id);
        if (goods != null) {
            goods.setImages(goodsImageMapper.findByGoodsId(id));
        }
        return goods;
    }

    public Goods getByBarCode(String barCode) {
        return goodsMapper.findByBarCode(barCode);
    }

    @Transactional
    public void add(Goods goods, List<String> imageUrls) {
        goodsMapper.insert(goods);
        if (imageUrls != null && !imageUrls.isEmpty()) {
            for (int i = 0; i < imageUrls.size(); i++) {
                GoodsImage image = new GoodsImage();
                image.setGoodsId(goods.getId());
                image.setImageUrl(imageUrls.get(i));
                image.setSort(i);
                goodsImageMapper.insert(image);
            }
        }
    }

    @Transactional
    public void update(Goods goods, List<String> imageUrls) {
        goodsMapper.update(goods);
        if (imageUrls != null) {
            goodsImageMapper.deleteByGoodsId(goods.getId());
            for (int i = 0; i < imageUrls.size(); i++) {
                GoodsImage image = new GoodsImage();
                image.setGoodsId(goods.getId());
                image.setImageUrl(imageUrls.get(i));
                image.setSort(i);
                goodsImageMapper.insert(image);
            }
        }
    }

    public void updateSaleStatus(Long id, Integer isOnSale) {
        goodsMapper.updateSaleStatus(id, isOnSale);
    }

    public void delete(Long id) {
        goodsMapper.delete(id);
    }

    public List<Goods> getLowStock() {
        return goodsMapper.findLowStock();
    }

    public List<Goods> getExpiringSoon(Integer days) {
        return goodsMapper.findExpiringSoon(days);
    }
}



