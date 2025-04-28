package com.example.demo.service;

import com.example.demo.model.ExpirationInfo;
import com.example.demo.repository.ExpirationInfoRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.w3c.dom.*;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.xml.sax.InputSource;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ExpirationInfoService {

    private final ExpirationInfoRepository expirationInfoRepository;

    @Value("${public_data_api_url}")
    private String apiUrl;

    @Value("${public_data_api_key}")
    private String apiKey;

    private final RestTemplate restTemplate;

    public ExpirationInfoService(ExpirationInfoRepository expirationInfoRepository, RestTemplate restTemplate) {
        this.expirationInfoRepository = expirationInfoRepository;
        this.restTemplate = restTemplate;
    }

    @Transactional
    public void fetchAndSaveExpirationData() {
        // expirationInfoRepository.deleteAll(); // 필요 시 전체 삭제
        int start = 1;
        int end = 100;
        int totalSaved = 0;

        while (true) {
            try {
                String url = String.format("%s/%s/C005/xml/%d/%d", apiUrl, apiKey, start, end);
                System.out.println("🔄 API 호출 중: " + url);


                // ✅ 여기부터 인코딩 처리 코드 삽입
                DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
                DocumentBuilder builder = factory.newDocumentBuilder();

                InputStream inputStream = new URL(url).openStream();
                InputSource inputSource = new InputSource(new InputStreamReader(inputStream, StandardCharsets.UTF_8)); // ✅ UTF-8로 수정
                Document doc = builder.parse(inputSource);
                NodeList nodeList = doc.getElementsByTagName("row");

                if (nodeList.getLength() == 0) {
                    System.out.println("✅ 모든 데이터를 가져왔습니다. 총 " + totalSaved + "개 저장 완료.");
                    break;
                }

                List<ExpirationInfo> expirationList = new ArrayList<>();

                for (int i = 0; i < nodeList.getLength(); i++) {
                    Node node = nodeList.item(i);
                    if (node.getNodeType() == Node.ELEMENT_NODE) {
                        Element element = (Element) node;
                        String productName = getElementValue(element, "PRDLST_NM");
                        String category = getElementValue(element, "PRDLST_CDNM");
                        String shelfLife = getElementValue(element, "POG_DAYCNT");

                        // ✅ 숫자만 추출 (ex: "12개월" -> 360일로 저장)
                        shelfLife = extractShelfLifeInDays(shelfLife);

                        expirationList.add(new ExpirationInfo(null, productName, category, shelfLife));

                        System.out.println("📝 저장 예정: " + productName + " / " + category + " / " + shelfLife + "일");
                    }
                }

                expirationInfoRepository.saveAll(expirationList);
                totalSaved += expirationList.size();

                System.out.println("✅ 현재까지 " + totalSaved + "개의 데이터를 저장했습니다.");

                start += 1000;
                end += 1000;
                Thread.sleep(500);
            } catch (Exception e) {
                System.err.println("❌ API 호출 중 오류 발생: " + e.getMessage());
                break;
            }
        }
    }

    private String getElementValue(Element element, String tagName) {
        try {
            Node node = element.getElementsByTagName(tagName).item(0);
            if (node == null) return "N/A";
            return node.getTextContent().trim();
        } catch (Exception e) {
            return "N/A";
        }
    }

    // ✅ 유통기한을 숫자로 추출해서 "일"로 변환 (3개월 → 90)
    private String extractShelfLifeInDays(String raw) {
        if (raw == null) return "0";
        Matcher dayMatcher = Pattern.compile("(\\d+)\\s*일").matcher(raw);
        Matcher monthMatcher = Pattern.compile("(\\d+)\\s*개월").matcher(raw);

        if (dayMatcher.find()) {
            return dayMatcher.group(1);
        } else if (monthMatcher.find()) {
            return String.valueOf(Integer.parseInt(monthMatcher.group(1)) * 30);
        }

        return "0";
    }

    public List<ExpirationInfo> getAllExpirationData() {
        return expirationInfoRepository.findAll();
    }
    public void printAllExpirationData() {
        List<ExpirationInfo> list = expirationInfoRepository.findAll();
        for (ExpirationInfo info : list) {
            System.out.println("🧾 제품명: " + info.getProductName() +
                    " / 카테고리: " + info.getCategory() +
                    " / 유통기한: " + info.getShelfLife() + "일");
        }
    }
}
