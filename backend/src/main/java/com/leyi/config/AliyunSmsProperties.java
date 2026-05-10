package com.leyi.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "aliyun.sms")
public class AliyunSmsProperties {

    private String accessKeyId;
    private String accessKeySecret;
    private String endpoint = "dypnsapi.aliyuncs.com";
    private String signName;
    private String templateCode;
    private Integer validMinutes = 5;
}
