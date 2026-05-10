package com.leyi.controller;

import com.leyi.common.Result;
import com.leyi.exception.BusinessException;
import com.leyi.security.AuthContext;
import com.leyi.service.AdminService;
import com.leyi.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final Pattern PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$");
    private static final Pattern CODE_PATTERN = Pattern.compile("^\\d{6}$");

    @Autowired
    private UserService userService;

    @Autowired
    private AdminService adminService;

    @PostMapping("/sendCode")
    public Result<?> sendCode(@RequestBody Map<String, String> params) {
        String phone = normalize(params.get("phone"));
        validatePhone(phone);
        userService.sendCode(phone);
        return Result.success("验证码已发送，请查收短信", null);
    }

    @PostMapping("/login")
    public Result<?> login(@RequestBody Map<String, String> params) {
        String phone = normalize(params.get("phone"));
        String code = normalize(params.get("code"));
        validatePhone(phone);
        if (!CODE_PATTERN.matcher(code).matches()) {
            throw new BusinessException(400, "请输入6位数字验证码");
        }
        return Result.success(userService.login(phone, code));
    }

    @PostMapping("/admin/login")
    public Result<?> adminLogin(@RequestBody Map<String, String> params) {
        String phone = normalize(params.get("phone"));
        String password = normalize(params.get("password"));
        validatePhone(phone);
        if (password.isEmpty()) {
            throw new BusinessException(400, "请输入密码");
        }
        return Result.success(adminService.login(phone, password));
    }

    @GetMapping("/info")
    public Result<?> getInfo(HttpServletRequest request) {
        String userType = AuthContext.getUserType(request);
        if ("admin".equals(userType)) {
            return Result.success(adminService.getById(AuthContext.getAdminId(request)));
        }
        if ("user".equals(userType)) {
            return Result.success(userService.getById(AuthContext.getUserId(request)));
        }
        throw new BusinessException(403, "无效登录身份");
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim();
    }

    private void validatePhone(String phone) {
        if (!PHONE_PATTERN.matcher(phone).matches()) {
            throw new BusinessException(400, "请输入正确的手机号");
        }
    }
}
