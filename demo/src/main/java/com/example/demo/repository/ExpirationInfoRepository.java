package com.example.demo.repository;

import com.example.demo.model.ExpirationInfo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.List;

@Repository
public interface ExpirationInfoRepository extends JpaRepository<ExpirationInfo, Long> {

    List<ExpirationInfo> findByProductNameAndCategoryAndShelfLife(String productName, String category, String shelfLife);

    void deleteByProductNameAndCategoryAndShelfLife(String productName, String category, String shelfLife);

    // ✅ 음식 이름으로 검색하는 API에서 사용할 메서드
    Optional<ExpirationInfo> findFirstByProductNameContaining(String productName);
}
