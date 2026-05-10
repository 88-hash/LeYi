package com.leyi.service;

import com.leyi.config.DatabaseSchemaSupport;
import com.leyi.entity.User;
import com.leyi.exception.BusinessException;
import com.leyi.mapper.UserMapper;
import com.leyi.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class UserService {

    private static final long CODE_EXPIRE_MILLIS = 5 * 60 * 1000L;
    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private DatabaseSchemaSupport databaseSchemaSupport;

    @Autowired
    private SmsService smsService;

    private static final ConcurrentHashMap<String, CodeEntry> CODE_MAP = new ConcurrentHashMap<>();

    public void sendCode(String phone) {
        String code = String.format("%06d", (int) (Math.random() * 1_000_000));
        CODE_MAP.put(phone, new CodeEntry(code, System.currentTimeMillis() + CODE_EXPIRE_MILLIS));
        try {
            smsService.sendLoginCode(phone, code);
            log.info("Login verification code sent. phone={}", phone);
        } catch (BusinessException e) {
            CODE_MAP.remove(phone);
            throw e;
        }
    }

    public Map<String, Object> login(String phone, String code) {
        CodeEntry entry = CODE_MAP.get(phone);
        if (entry == null || entry.isExpired() || !entry.getCode().equals(code)) {
            CODE_MAP.remove(phone);
            throw new BusinessException(400, "验证码错误或已失效");
        }
        CODE_MAP.remove(phone);

        User user = userMapper.findByPhone(phone);
        if (user == null) {
            user = new User();
            user.setPhone(phone);
            user.setName("用户" + phone.substring(7));
            user.setAvatar("");
            user.setSignature("");
            if (databaseSchemaSupport.hasUserSignatureColumn()) {
                userMapper.insert(user);
            } else {
                userMapper.insertLegacy(user);
            }
        } else {
            userMapper.updateLoginTime(user.getId());
        }

        String token = jwtUtil.generateToken(user.getId(), phone, "user");

        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("user", sanitizeUser(userMapper.findById(user.getId())));
        return result;
    }

    public User getById(Long id) {
        return sanitizeUser(userMapper.findById(id));
    }

    public User update(User user) {
        if (user.getId() == null) {
            throw new BusinessException(400, "用户ID不能为空");
        }
        User existing = userMapper.findById(user.getId());
        if (existing == null) {
            throw new BusinessException(400, "用户不存在");
        }

        existing.setName(normalizeName(user.getName(), existing.getPhone()));
        existing.setAvatar(normalizeAvatar(user.getAvatar()));
        existing.setSignature(normalizeSignature(user.getSignature()));

        if (databaseSchemaSupport.hasUserSignatureColumn()) {
            userMapper.update(existing);
        } else {
            userMapper.updateLegacy(existing);
        }

        return sanitizeUser(userMapper.findById(existing.getId()));
    }

    private User sanitizeUser(User user) {
        if (user == null) {
            return null;
        }
        if (user.getAvatar() == null) {
            user.setAvatar("");
        }
        if (user.getSignature() == null) {
            user.setSignature("");
        }
        return user;
    }

    private String normalizeName(String value, String fallbackPhone) {
        String text = value == null ? "" : value.trim();
        if (text.isEmpty()) {
            return fallbackPhone == null || fallbackPhone.length() < 4
                    ? "LeYi会员"
                    : "用户" + fallbackPhone.substring(fallbackPhone.length() - 4);
        }
        if (text.length() > 20) {
            throw new BusinessException(400, "昵称不能超过20个字符");
        }
        return text;
    }

    private String normalizeAvatar(String value) {
        return value == null ? "" : value.trim();
    }

    private String normalizeSignature(String value) {
        String text = value == null ? "" : value.trim();
        if (text.length() > 80) {
            throw new BusinessException(400, "个人说明不能超过80个字符");
        }
        return text;
    }

    private static class CodeEntry {
        private final String code;
        private final long expireAt;

        private CodeEntry(String code, long expireAt) {
            this.code = code;
            this.expireAt = expireAt;
        }

        private String getCode() {
            return code;
        }

        private boolean isExpired() {
            return System.currentTimeMillis() > expireAt;
        }
    }
}
