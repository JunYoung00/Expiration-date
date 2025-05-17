package com.example.demo.controller;

import com.example.demo.model.ExpirationInfo;
import com.example.demo.service.ExpirationInfoService;
import com.example.demo.repository.ExpirationInfoRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@CrossOrigin
@RestController
@RequestMapping("/")
public class ExpirationInfoController {

    private final ExpirationInfoService expirationInfoService;
    private final ExpirationInfoRepository expirationInfoRepository;

    public ExpirationInfoController(ExpirationInfoService expirationInfoService,
                                    ExpirationInfoRepository expirationInfoRepository) {
        this.expirationInfoService = expirationInfoService;
        this.expirationInfoRepository = expirationInfoRepository;
    }

    @GetMapping("/")
    public String home() {
        return "✅ 서버가 정상적으로 실행 중입니다!";
    }

    @GetMapping("/fetch")
    public String fetchData() {
        expirationInfoService.fetchAndSaveExpirationData();
        return "데이터가 MariaDB에 저장되었습니다!";
    }

    @GetMapping(value = "/list", produces = "application/json; charset=UTF-8")
    public List<ExpirationInfo> getAllData() {
        return expirationInfoService.getAllExpirationData();
    }

    // ✅ 여기가 추가된 부분!
    @GetMapping(value = "/search", produces = "application/json; charset=UTF-8")
    public ResponseEntity<?> searchByProductName(@RequestParam(name = "name") String name) {
        System.out.println("검색어: " + name);
        List<ExpirationInfo> infos = expirationInfoRepository.findByProductNameContaining(name);
        if (!infos.isEmpty()) {
            return ResponseEntity.ok(infos); // 🔥 여러개 리스트로 반환
        } else {
            return ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .contentType(MediaType.valueOf("text/plain; charset=UTF-8"))
                    .body("DB에 등록된 품목이 없습니다.");
        }
    }

}
