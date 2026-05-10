package com.leyi.entity;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class Goods {
    private Long id;
    private Long categoryId;
    private String name;
    private BigDecimal price;
    private Integer stock;
    private Integer safetyStock;
    private String barCode;
    private String imageUrl;
    private String description;
    private String promotionTag;
    private Integer isOnSale;
    private Integer isDeleted;
    private LocalDate expireDate;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String categoryName;
    private Long salesCount;
    private List<GoodsImage> images;
}



