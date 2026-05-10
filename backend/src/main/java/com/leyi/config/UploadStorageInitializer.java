package com.leyi.config;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@Component
public class UploadStorageInitializer {

    @Value("${upload.path}")
    private String uploadPath;

    @PostConstruct
    public void init() {
        Path uploadRoot = Path.of(uploadPath).toAbsolutePath().normalize();
        try {
            Files.createDirectories(uploadRoot.resolve("goods"));
        } catch (IOException e) {
            throw new IllegalStateException("初始化上传目录失败: " + uploadRoot, e);
        }
    }
}
