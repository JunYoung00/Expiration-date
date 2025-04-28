package com.example.demo;

import com.example.demo.service.ExpirationInfoService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class DemoApplication {

	public static void main(String[] args) {
		SpringApplication.run(DemoApplication.class, args);
	}

	/*@Bean
	CommandLineRunner run(ExpirationInfoService expirationInfoService) {
		return args -> {
			System.out.println("🔥 서버 실행과 함께 데이터 가져오기 시작...");
			expirationInfoService.fetchAndSaveExpirationData();
		};
	}*/
	@Bean
	CommandLineRunner run(ExpirationInfoService expirationInfoService) {
		return args -> {
			// expirationInfoService.fetchAndSaveExpirationData(); // 저장
			expirationInfoService.printAllExpirationData(); // ✅ 저장된 데이터 출력
		};
	}
}