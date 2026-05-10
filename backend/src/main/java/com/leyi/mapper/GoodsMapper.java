package com.leyi.mapper;

import com.leyi.entity.Goods;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface GoodsMapper {

    List<Goods> findList(@Param("categoryId") Long categoryId,
                         @Param("categoryIds") List<Long> categoryIds,
                         @Param("keyword") String keyword,
                         @Param("sort") String sort,
                         @Param("isOnSale") Integer isOnSale,
                         @Param("offset") Integer offset,
                         @Param("limit") Integer limit);

    Long countList(@Param("categoryId") Long categoryId,
                   @Param("categoryIds") List<Long> categoryIds,
                   @Param("keyword") String keyword,
                   @Param("isOnSale") Integer isOnSale);

    @Select("SELECT g.*, c.name as category_name FROM goods g LEFT JOIN category c ON g.category_id = c.id WHERE g.id = #{id} AND g.is_deleted = 0")
    Goods findById(Long id);

    @Select("SELECT * FROM goods WHERE bar_code = #{barCode} AND is_deleted = 0")
    Goods findByBarCode(String barCode);

    @Insert("INSERT INTO goods(category_id, name, price, stock, safety_stock, bar_code, image_url, description, promotion_tag, is_on_sale, expire_date) " +
            "VALUES(#{categoryId}, #{name}, #{price}, #{stock}, #{safetyStock}, #{barCode}, #{imageUrl}, #{description}, #{promotionTag}, #{isOnSale}, #{expireDate})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(Goods goods);

    int update(Goods goods);

    @Update("UPDATE goods SET is_on_sale = #{isOnSale}, updated_at = NOW() WHERE id = #{id}")
    int updateSaleStatus(@Param("id") Long id, @Param("isOnSale") Integer isOnSale);

    @Update("UPDATE goods SET stock = stock - #{quantity}, updated_at = NOW() WHERE id = #{id} AND stock >= #{quantity}")
    int decreaseStock(@Param("id") Long id, @Param("quantity") Integer quantity);

    @Update("UPDATE goods SET stock = stock + #{quantity}, updated_at = NOW() WHERE id = #{id}")
    int increaseStock(@Param("id") Long id, @Param("quantity") Integer quantity);

    @Update("UPDATE goods SET is_deleted = 1, updated_at = NOW() WHERE id = #{id}")
    int delete(Long id);

    @Select("SELECT * FROM goods WHERE stock < safety_stock AND is_deleted = 0 AND is_on_sale = 1")
    List<Goods> findLowStock();

    @Select("SELECT * FROM goods WHERE expire_date IS NOT NULL AND expire_date <= DATE_ADD(CURDATE(), INTERVAL #{days} DAY) AND is_deleted = 0 AND is_on_sale = 1")
    List<Goods> findExpiringSoon(Integer days);
}
