package com.kubernetes.platform.repository;

import com.kubernetes.platform.model.Item;
import com.kubernetes.platform.model.ItemStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ItemRepository extends JpaRepository<Item, Long> {

    List<Item> findByStatus(ItemStatus status);

    List<Item> findByCategory(String category);

    List<Item> findByStatusAndCategory(ItemStatus status, String category);

    Page<Item> findByNameContainingIgnoreCase(String name, Pageable pageable);

    @Query("SELECT DISTINCT i.category FROM Item i ORDER BY i.category")
    List<String> findDistinctCategories();

    @Query("SELECT COUNT(i) FROM Item i WHERE i.status = :status")
    long countByStatus(@Param("status") ItemStatus status);

    @Query("SELECT i FROM Item i WHERE i.name LIKE %:keyword% OR i.description LIKE %:keyword%")
    List<Item> searchByKeyword(@Param("keyword") String keyword);
}