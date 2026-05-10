package com.leyi.service;

import com.aliyun.dypnsapi20170525.Client;
import com.aliyun.dypnsapi20170525.models.SendSmsVerifyCodeRequest;
import com.aliyun.dypnsapi20170525.models.SendSmsVerifyCodeResponse;
import com.aliyun.teaopenapi.models.Config;
import com.aliyun.teautil.models.RuntimeOptions;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.leyi.config.AliyunSmsProperties;
import com.leyi.exception.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.Map;

@Service
public class SmsService {

    private static final Logger log = LoggerFactory.getLogger(SmsService.class);

    private final AliyunSmsProperties properties;
    private final ObjectMapper objectMapper;

    public SmsService(AliyunSmsProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper;
    }

    public void sendLoginCode(String phone, String code) {
        validateConfig();
        try {
            Client client = createClient();
            SendSmsVerifyCodeRequest request = new SendSmsVerifyCodeRequest()
                    .setPhoneNumber(phone)
                    .setSignName(properties.getSignName())
                    .setTemplateCode(properties.getTemplateCode())
                    .setTemplateParam(buildTemplateParam(code));
            SendSmsVerifyCodeResponse response = client.sendSmsVerifyCodeWithOptions(request, new RuntimeOptions());
            String responseCode = response.getBody() == null ? null : response.getBody().getCode();
            Boolean success = response.getBody() == null ? null : response.getBody().getSuccess();
            if (!"OK".equals(responseCode) || !Boolean.TRUE.equals(success)) {
                String message = response.getBody() == null ? "无响应" : response.getBody().getMessage();
                log.error("Aliyun SMS authentication send failed. phone={}, code={}, message={}", phone, responseCode, message);
                throw new BusinessException(500, buildFailureMessage(responseCode, message));
            }
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("Aliyun SMS authentication send exception. phone={}", phone, e);
            throw new BusinessException(500, "短信发送失败，请稍后重试");
        }
    }

    private Client createClient() throws Exception {
        Config config = new Config()
                .setAccessKeyId(properties.getAccessKeyId())
                .setAccessKeySecret(properties.getAccessKeySecret());
        config.endpoint = properties.getEndpoint();
        return new Client(config);
    }

    private String buildTemplateParam(String code) throws JsonProcessingException {
        return objectMapper.writeValueAsString(Map.of(
                "code", code,
                "min", String.valueOf(properties.getValidMinutes())
        ));
    }

    private void validateConfig() {
        if (!StringUtils.hasText(properties.getAccessKeyId())
                || !StringUtils.hasText(properties.getAccessKeySecret())
                || !StringUtils.hasText(properties.getSignName())
                || !StringUtils.hasText(properties.getTemplateCode())) {
            log.error("Aliyun SMS config is incomplete. signNameConfigured={}, templateCodeConfigured={}",
                    StringUtils.hasText(properties.getSignName()),
                    StringUtils.hasText(properties.getTemplateCode()));
            throw new BusinessException(500, "短信服务配置不完整，请联系管理员");
        }
    }

    private String buildFailureMessage(String code, String message) {
        String detail = StringUtils.hasText(message) ? message : code;
        if (!StringUtils.hasText(detail)) {
            return "短信发送失败，请稍后重试";
        }
        return "短信发送失败：" + detail;
    }
}
