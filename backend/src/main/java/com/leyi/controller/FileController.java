package com.leyi.controller;

import com.leyi.common.Result;
import com.leyi.exception.BusinessException;
import com.leyi.security.AuthGuard;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;
import java.util.UUID;
import javax.imageio.ImageIO;

@RestController
@RequestMapping("/api/file")
public class FileController {

    private static final Set<String> ALLOWED_SUFFIXES = Set.of(".jpg", ".jpeg", ".png");
    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of("image/jpeg", "image/png");

    @Value("${upload.path}")
    private String uploadPath;

    @Value("${upload.max-size}")
    private long uploadMaxSize;

    @Autowired
    private AuthGuard authGuard;

    @PostMapping("/upload")
    public Result<?> upload(HttpServletRequest request, @RequestParam("file") MultipartFile file) {
        authGuard.requireManager(request);
        validateFile(file);

        String originalFilename = file.getOriginalFilename();
        String suffix = originalFilename.substring(originalFilename.lastIndexOf(".")).toLowerCase();
        String newFilename = UUID.randomUUID().toString().replace("-", "") + suffix;

        Path goodsDir = Path.of(uploadPath).toAbsolutePath().normalize().resolve("goods");
        Path targetFile = goodsDir.resolve(newFilename);

        try {
            Files.createDirectories(goodsDir);
            file.transferTo(targetFile);
            return Result.success("/uploads/goods/" + newFilename);
        } catch (IOException e) {
            throw new BusinessException(500, "上传失败");
        }
    }

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException(400, "请选择文件");
        }

        if (file.getSize() <= 0 || file.getSize() > uploadMaxSize) {
            throw new BusinessException(400, "文件大小超出限制");
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || !originalFilename.contains(".")) {
            throw new BusinessException(400, "文件名格式错误");
        }

        String suffix = originalFilename.substring(originalFilename.lastIndexOf(".")).toLowerCase();
        if (!ALLOWED_SUFFIXES.contains(suffix)) {
            throw new BusinessException(400, "仅支持 JPG、JPEG、PNG 图片");
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType.toLowerCase())) {
            throw new BusinessException(400, "文件类型不支持");
        }

        try (InputStream inputStream = file.getInputStream()) {
            BufferedImage image = ImageIO.read(inputStream);
            if (image == null) {
                throw new BusinessException(400, "上传文件不是有效图片");
            }
        } catch (IOException e) {
            throw new BusinessException(400, "图片内容校验失败");
        }
    }
}
