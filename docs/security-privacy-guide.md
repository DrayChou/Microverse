# AI 系统安全与隐私保护指南

## 📋 概述

本文档详细描述了 AI 驱动虚拟世界系统的安全架构、隐私保护机制和合规策略。涵盖了数据安全、访问控制、AI 安全、隐私保护等多个维度的安全实践。

## 🔐 安全架构概览

### 1. 多层安全防护体系

```
┌─────────────────────────────────────────────────────────────────┐
│                     应用安全层 (Application Security)           │
├─────────────────────────────────────────────────────────────────┤
│  输入验证  │  输出过滤  │  权限控制  │  会话管理                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API 安全层 (API Security)                     │
├─────────────────────────────────────────────────────────────────┤
│  认证授权  │  限流控制  │  加密传输  │  API 密钥管理             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   AI 安全层 (AI Security)                       │
├─────────────────────────────────────────────────────────────────┤
│  Prompt 注入防护  │  模型安全  │  数据脱敏  │  输出监控         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   数据安全层 (Data Security)                     │
├─────────────────────────────────────────────────────────────────┤
│  数据加密  │  访问控制  │  备份恢复  │  审计日志                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   基础设施层 (Infrastructure Security)           │
├─────────────────────────────────────────────────────────────────┤
│  网络安全  │  容器安全  │  主机安全  │  密钥管理                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🛡️ 身份认证与授权

### 1. 多因素认证 (MFA)

#### JWT + MFA 实现
```typescript
// 认证服务接口
interface AuthenticationService {
  // 用户登录
  login(credentials: LoginCredentials): Promise<AuthResult>;

  // 多因素认证验证
  verifyMFA(user_id: string, mfa_code: string): Promise<MFAVerificationResult>;

  // 刷新令牌
  refreshToken(refresh_token: string): Promise<TokenRefreshResult>;

  // 用户登出
  logout(access_token: string): Promise<void>;
}

interface LoginCredentials {
  username: string;
  password: string;
  mfa_code?: string; // 可选的MFA代码
  remember_device?: boolean;
}

interface AuthResult {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
  requires_mfa: boolean;
  mfa_methods: MFAMethod[];
}

// MFA 方法
enum MFAMethod {
  TOTP = 'totp',           // 基于时间的一次性密码
  SMS = 'sms',             // 短信验证码
  EMAIL = 'email',         // 邮箱验证码
  HARDWARE_TOKEN = 'hardware_token' // 硬件令牌
}

// JWT 配置
const JWT_CONFIG = {
  algorithm: 'RS256',
  accessTokenExpiry: '15m',
  refreshTokenExpiry: '7d',
  issuer: 'ai-world-platform',
  audience: 'ai-world-users'
};

// 中间件实现
export const authMiddleware = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const token = extractTokenFromRequest(req);
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = await verifyJWT(token);
    req.user = decoded;

    // 检查会话状态
    const session = await getSession(decoded.user_id);
    if (!session || session.is_revoked) {
      return res.status(401).json({ error: 'Invalid session' });
    }

    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};
```

### 2. 基于角色的访问控制 (RBAC)

#### 权限模型设计
```sql
-- 角色表
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    is_system_role BOOLEAN DEFAULT false,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 权限表
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) UNIQUE NOT NULL,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 角色权限关联表
CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,

    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID REFERENCES users(id),

    PRIMARY KEY (role_id, permission_id)
);

-- 用户角色关联表
CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,

    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    expires_at TIMESTAMP WITH TIME ZONE, // 可选的过期时间
    is_active BOOLEAN DEFAULT true,

    PRIMARY KEY (user_id, role_id)
);

-- 数据级权限表 (针对特定资源的访问控制)
CREATE TABLE resource_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    resource_type VARCHAR(50) NOT NULL, -- character, conversation, memory, etc.
    resource_id UUID NOT NULL,
    permission_level VARCHAR(20) NOT NULL, -- read, write, admin, owner

    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID REFERENCES users(id),
    expires_at TIMESTAMP WITH TIME ZONE,

    UNIQUE(user_id, resource_type, resource_id)
);
```

#### 权限检查中间件
```typescript
interface PermissionChecker {
  // 检查用户权限
  hasPermission(user_id: string, permission: string): Promise<boolean>;

  // 检查资源访问权限
  hasResourceAccess(
    user_id: string,
    resource_type: string,
    resource_id: string,
    required_level: string
  ): Promise<boolean>;

  // 获取用户所有权限
  getUserPermissions(user_id: string): Promise<Permission[]>;

  // 检查角色权限
  hasRolePermission(user_id: string, role_name: string, permission: string): Promise<boolean>;
}

// 权限装饰器
export const RequirePermission = (permission: string) => {
  return (target: any, propertyName: string, descriptor: PropertyDescriptor) => {
    const method = descriptor.value;

    descriptor.value = async function (...args: any[]) {
      const user_id = this.getUserFromContext();
      const hasPermission = await this.permissionChecker.hasPermission(user_id, permission);

      if (!hasPermission) {
        throw new UnauthorizedError(`Missing required permission: ${permission}`);
      }

      return method.apply(this, args);
    };
  };
};

// 使用示例
class CharacterController {
  @RequirePermission('character:read')
  async getCharacter(character_id: string): Promise<Character> {
    return this.characterService.getCharacter(character_id);
  }

  @RequirePermission('character:write')
  async updateCharacter(character_id: string, updates: Partial<Character>): Promise<Character> {
    return this.characterService.updateCharacter(character_id, updates);
  }
}
```

## 🔒 数据加密与保护

### 1. 传输层安全

#### TLS/SSL 配置
```nginx
# Nginx HTTPS 配置
server {
    listen 443 ssl http2;
    server_name ai-world.example.com;

    # SSL 证书配置
    ssl_certificate /etc/ssl/certs/ai-world.crt;
    ssl_certificate_key /etc/ssl/private/ai-world.key;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 其他安全头
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name ai-world.example.com;
    return 301 https://$server_name$request_uri;
}
```

### 2. 存储加密

#### 数据库加密
```sql
-- 启用 PostgreSQL 透明数据加密 (TDE)
-- 注意：这需要企业版 PostgreSQL 或第三方扩展

-- 字段级加密
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 敏感数据加密函数
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(data TEXT, encryption_key TEXT)
RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(data, encryption_key, 'cipher-algo=aes256');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 解密函数
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(encrypted_data BYTEA, encryption_key TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(encrypted_data, encryption_key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 使用示例
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 加密存储敏感信息
    encrypted_personal_info BYTEA,
    encrypted_preferences BYTEA,

    -- 非敏感信息
    display_name VARCHAR(100),
    avatar_url VARCHAR(500),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 加密密钥管理
CREATE TABLE encryption_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key_name VARCHAR(100) UNIQUE NOT NULL,
    encrypted_key BYTEA NOT NULL, -- 用主密钥加密的密钥
    key_type VARCHAR(50) NOT NULL, -- data, ai_model, user_data
    algorithm VARCHAR(50) DEFAULT 'aes256',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);
```

#### 文件加密存储
```typescript
interface FileEncryptionService {
  // 加密文件
  encryptFile(file: Buffer, encryption_key: string): Promise<EncryptedFile>;

  // 解密文件
  decryptFile(encrypted_file: EncryptedFile, encryption_key: string): Promise<Buffer>;

  // 生成加密密钥
  generateEncryptionKey(): Promise<string>;

  // 安全删除密钥
  secureDeleteKey(key_id: string): Promise<void>;
}

interface EncryptedFile {
  encrypted_data: Buffer;
  iv: Buffer; // 初始化向量
  auth_tag: Buffer; // 认证标签
  algorithm: string;
  key_id: string;
}

// 加密实现
import crypto from 'crypto';

class AESEncryptionService implements FileEncryptionService {
  private readonly ALGORITHM = 'aes-256-gcm';
  private readonly KEY_LENGTH = 32; // 256 bits
  private readonly IV_LENGTH = 16;  // 128 bits
  private readonly AUTH_TAG_LENGTH = 16; // 128 bits

  async generateEncryptionKey(): Promise<string> {
    return crypto.randomBytes(this.KEY_LENGTH).toString('base64');
  }

  async encryptFile(file: Buffer, encryption_key: string): Promise<EncryptedFile> {
    const key = Buffer.from(encryption_key, 'base64');
    const iv = crypto.randomBytes(this.IV_LENGTH);

    const cipher = crypto.createCipher(this.ALGORITHM, key);
    cipher.setAAD(Buffer.from('ai-world-file'));

    let encrypted = cipher.update(file);
    encrypted = Buffer.concat([encrypted, cipher.final()]);

    const authTag = cipher.getAuthTag();

    return {
      encrypted_data: encrypted,
      iv: iv,
      auth_tag: authTag,
      algorithm: this.ALGORITHM,
      key_id: await this.storeKey(encryption_key)
    };
  }

  async decryptFile(encrypted_file: EncryptedFile, encryption_key: string): Promise<Buffer> {
    const key = Buffer.from(encryption_key, 'base64');

    const decipher = crypto.createDecipher(this.ALGORITHM, key);
    decipher.setAAD(Buffer.from('ai-world-file'));
    decipher.setAuthTag(encrypted_file.auth_tag);

    let decrypted = decipher.update(encrypted_file.encrypted_data);
    decrypted = Buffer.concat([decrypted, decipher.final()]);

    return decrypted;
  }

  private async storeKey(key: string): Promise<string> {
    const key_id = crypto.randomUUID();
    // 将密钥安全存储到密钥管理服务
    await this.keyManagementService.storeKey(key_id, key);
    return key_id;
  }
}
```

## 🤖 AI 安全机制

### 1. Prompt 注入防护

#### 输入过滤与验证
```typescript
interface PromptSecurityService {
  // 检测恶意 Prompt
  detectMaliciousPrompt(prompt: string): Promise<ThreatDetectionResult>;

  // 清理和标准化 Prompt
  sanitizePrompt(prompt: string): Promise<string>;

  // 验证 Prompt 长度和内容
  validatePrompt(prompt: string): Promise<PromptValidationResult>;

  // 检测 Prompt 注入攻击
  detectPromptInjection(prompt: string): Promise<InjectionDetectionResult>;
}

interface ThreatDetectionResult {
  is_malicious: boolean;
  threat_level: 'low' | 'medium' | 'high' | 'critical';
  threat_types: ThreatType[];
  confidence: number;
  recommendations: string[];
}

enum ThreatType {
  PROMPT_INJECTION = 'prompt_injection',
  SYSTEM_ROLE_OVERRIDE = 'system_role_override',
  INFORMATION_EXTRACTION = 'information_extraction',
  MALICIOUS_INSTRUCTION = 'malicious_instruction',
  PRIVACY_VIOLATION = 'privacy_violation'
}

// Prompt 注入检测实现
class PromptInjectionDetector {
  private readonly INJECTION_PATTERNS = [
    /ignore\s+previous\s+instructions/i,
    /system\s*:\s*/i,
    /\[SYSTEM\]/i,
    /\[INST\]/i,
    /human\s*:\s*/i,
    /assistant\s*:\s*/i,
    /\{\{.*\}\}/g, // 模板注入
    /<.*>/g, // 标签注入
    /```[\s\S]*?```/g, // 代码块注入
  ];

  private readonly MALICIOUS_KEYWORDS = [
    'password', 'secret', 'api_key', 'token', 'credentials',
    'confidential', 'private', 'sensitive', 'admin', 'root',
    'bypass', 'override', 'exploit', 'vulnerability'
  ];

  async detectPromptInjection(prompt: string): Promise<InjectionDetectionResult> {
    const result: InjectionDetectionResult = {
      has_injection: false,
      injection_patterns: [],
      confidence: 0,
      sanitized_prompt: prompt
    };

    // 检测注入模式
    for (const pattern of this.INJECTION_PATTERNS) {
      const matches = prompt.match(pattern);
      if (matches) {
        result.has_injection = true;
        result.injection_patterns.push({
          pattern: pattern.source,
          matches: matches,
          severity: this.calculateSeverity(matches)
        });
      }
    }

    // 检测恶意关键词
    const foundKeywords = this.MALICIOUS_KEYWORDS.filter(keyword =>
      prompt.toLowerCase().includes(keyword.toLowerCase())
    );

    if (foundKeywords.length > 0) {
      result.has_injection = true;
      result.malicious_keywords = foundKeywords;
    }

    // 计算置信度
    result.confidence = this.calculateConfidence(result);

    // 清理 Prompt
    if (result.has_injection) {
      result.sanitized_prompt = await this.sanitizePrompt(prompt);
    }

    return result;
  }

  private sanitizePrompt(prompt: string): string {
    let sanitized = prompt;

    // 移除注入模式
    for (const pattern of this.INJECTION_PATTERNS) {
      sanitized = sanitized.replace(pattern, '[FILTERED]');
    }

    // 移除特殊字符序列
    sanitized = sanitized.replace(/\{+/g, '');
    sanitized = sanitized.replace(/\}+/g, '');
    sanitized = sanitized.replace(/<+/g, '');
    sanitized = sanitized.replace(/>+/g, '');

    return sanitized.trim();
  }

  private calculateSeverity(matches: RegExpMatchArray): 'low' | 'medium' | 'high' {
    if (matches.length >= 3) return 'high';
    if (matches.length >= 2) return 'medium';
    return 'low';
  }

  private calculateConfidence(result: InjectionDetectionResult): number {
    let confidence = 0;

    // 基于注入模式数量
    confidence += result.injection_patterns.length * 0.3;

    // 基于恶意关键词数量
    confidence += (result.malicious_keywords?.length || 0) * 0.2;

    // 基于模式严重程度
    const highSeverityPatterns = result.injection_patterns.filter(p => p.severity === 'high').length;
    confidence += highSeverityPatterns * 0.4;

    return Math.min(confidence, 1.0);
  }
}
```

### 2. AI 输出监控

#### 内容过滤与安全检查
```typescript
interface AIOutputMonitor {
  // 检查输出内容安全性
  checkOutputSafety(output: string, context: OutputContext): Promise<SafetyCheckResult>;

  // 检测隐私泄露
  detectPrivacyLeakage(output: string): Promise<PrivacyLeakageResult>;

  // 内容分类
  classifyContent(output: string): Promise<ContentClassification>;

  // 实时监控
  monitorAIResponse(response: AIResponse): Promise<MonitoringResult>;
}

interface SafetyCheckResult {
  is_safe: boolean;
  risk_level: 'low' | 'medium' | 'high' | 'critical';
  detected_issues: SafetyIssue[];
  recommendations: string[];
  should_block: boolean;
}

interface SafetyIssue {
  type: SafetyIssueType;
  severity: 'low' | 'medium' | 'high' | 'critical';
  description: string;
  confidence: number;
  position?: { start: number; end: number };
}

enum SafetyIssueType {
  HARMFUL_CONTENT = 'harmful_content',
  PRIVACY_VIOLATION = 'privacy_violation',
  INAPPROPRIATE_LANGUAGE = 'inappropriate_language',
  MISINFORMATION = 'misinformation',
  BIASED_CONTENT = 'biased_content',
  SECURITY_RISK = 'security_risk'
}

// 输出监控实现
class AIOutputMonitorImpl implements AIOutputMonitor {
  private readonly HARMFUL_PATTERNS = [
    /violence|kill|harm|destroy/i,
    /hate|discriminate|racist|sexist/i,
    /illegal|criminal|fraud|scam/i,
    /self-harm|suicide|depression/i,
  ];

  private readonly PRIVACY_PATTERNS = [
    /\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b/, // 信用卡号
    /\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b/, // 社会安全号
    /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/, // 邮箱
    /\b(?:\d{1,3}\.){3}\d{1,3}\b/, // IP地址
  ];

  async checkOutputSafety(output: string, context: OutputContext): Promise<SafetyCheckResult> {
    const result: SafetyCheckResult = {
      is_safe: true,
      risk_level: 'low',
      detected_issues: [],
      recommendations: [],
      should_block: false
    };

    // 检查有害内容
    const harmfulIssues = this.detectHarmfulContent(output);
    result.detected_issues.push(...harmfulIssues);

    // 检查隐私泄露
    const privacyIssues = await this.detectPrivacyLeakage(output);
    result.detected_issues.push(...privacyIssues.detected_issues);

    // 检查不当语言
    const languageIssues = this.detectInappropriateLanguage(output);
    result.detected_issues.push(...languageIssues);

    // 评估风险等级
    result.risk_level = this.calculateRiskLevel(result.detected_issues);
    result.is_safe = result.risk_level !== 'high' && result.risk_level !== 'critical';
    result.should_block = result.risk_level === 'critical';

    // 生成建议
    result.recommendations = this.generateRecommendations(result.detected_issues);

    return result;
  }

  private detectHarmfulContent(output: string): SafetyIssue[] {
    const issues: SafetyIssue[] = [];

    for (const pattern of this.HARMFUL_PATTERNS) {
      const matches = output.match(pattern);
      if (matches) {
        issues.push({
          type: SafetyIssueType.HARMFUL_CONTENT,
          severity: 'high',
          description: `检测到潜在有害内容: ${matches[0]}`,
          confidence: 0.8,
          position: this.findPosition(output, matches[0])
        });
      }
    }

    return issues;
  }

  private async detectPrivacyLeakage(output: string): Promise<PrivacyLeakageResult> {
    const detectedIssues: SafetyIssue[] = [];
    const leakedData: LeakedData[] = [];

    for (const pattern of this.PRIVACY_PATTERNS) {
      const matches = output.match(pattern);
      if (matches) {
        for (const match of matches) {
          const dataType = this.identifyDataType(match);
          detectedIssues.push({
            type: SafetyIssueType.PRIVACY_VIOLATION,
            severity: 'critical',
            description: `检测到潜在隐私泄露: ${dataType}`,
            confidence: 0.9,
            position: this.findPosition(output, match)
          });

          leakedData.push({
            type: dataType,
            value: match,
            masked_value: this.maskSensitiveData(match)
          });
        }
      }
    }

    return {
      has_privacy_leak: detectedIssues.length > 0,
      detected_issues,
      leaked_data,
      risk_score: this.calculatePrivacyRisk(leakedData)
    };
  }

  private maskSensitiveData(data: string): string {
    if (data.includes('@')) { // 邮箱
      const [username, domain] = data.split('@');
      return `${username.substring(0, 2)}***@${domain}`;
    }
    return data.substring(0, 2) + '***' + data.substring(data.length - 2);
  }

  private calculateRiskLevel(issues: SafetyIssue[]): 'low' | 'medium' | 'high' | 'critical' {
    if (issues.some(issue => issue.severity === 'critical')) return 'critical';
    if (issues.some(issue => issue.severity === 'high')) return 'high';
    if (issues.some(issue => issue.severity === 'medium')) return 'medium';
    if (issues.length > 0) return 'low';
    return 'low';
  }

  private generateRecommendations(issues: SafetyIssue[]): string[] {
    const recommendations: string[] = [];

    if (issues.some(issue => issue.type === SafetyIssueType.HARMFUL_CONTENT)) {
      recommendations.push('建议重新生成响应，避免有害内容');
    }

    if (issues.some(issue => issue.type === SafetyIssueType.PRIVACY_VIOLATION)) {
      recommendations.push('检测到隐私泄露，建议立即阻止响应并调查数据来源');
    }

    if (issues.some(issue => issue.type === SafetyIssueType.INAPPROPRIATE_LANGUAGE)) {
      recommendations.push('建议过滤不当语言，保持专业礼貌的表达');
    }

    return recommendations;
  }
}
```

## 🔍 隐私保护机制

### 1. 数据脱敏

#### PII (个人身份信息) 检测与脱敏
```typescript
interface PIIDetectionService {
  // 检测 PII
  detectPII(text: string): Promise<PIIDetectionResult>;

  // 脱敏处理
  anonymizeText(text: string, options: AnonymizationOptions): Promise<string>;

  // 数据分类
  classifyDataSensitivity(data: any): Promise<SensitivityLevel>;
}

interface PIIDetectionResult {
  detected_pii: PIIEntity[];
    confidence: number;
    anonymized_text: string;
    risk_level: 'low' | 'medium' | 'high';
}

interface PIIEntity {
    type: PIIType;
    value: string;
    confidence: number;
    position: { start: number; end: number };
    masked_value: string;
}

enum PIIType {
    NAME = 'name',
    EMAIL = 'email',
    PHONE = 'phone',
    ADDRESS = 'address',
    CREDIT_CARD = 'credit_card',
    SSN = 'ssn',
    PASSPORT = 'passport',
    IP_ADDRESS = 'ip_address',
    MEDICAL_RECORD = 'medical_record'
}

// PII 检测实现
class PIIDetectionServiceImpl implements PIIDetectionService {
    private readonly PII_PATTERNS = {
        [PIIType.EMAIL]: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g,
        [PIIType.PHONE]: /\b(?:\+?1[-.\s]?)?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b/g,
        [PIIType.CREDIT_CARD]: /\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b/g,
        [PIIType.SSN]: /\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b/g,
        [PIIType.IP_ADDRESS]: /\b(?:\d{1,3}\.){3}\d{1,3}\b/g,
    };

    async detectPII(text: string): Promise<PIIDetectionResult> {
        const detected_pii: PIIEntity[] = [];

        // 检测各种类型的 PII
        for (const [type, pattern] of Object.entries(this.PII_PATTERNS)) {
            const matches = text.matchAll(new RegExp(pattern.source, pattern.flags));

            for (const match of matches) {
                const piiType = type as PIIType;
                const confidence = this.calculatePIIConfidence(match[0], piiType);

                detected_pii.push({
                    type: piiType,
                    value: match[0],
                    confidence,
                    position: {
                        start: match.index || 0,
                        end: (match.index || 0) + match[0].length
                    },
                    masked_value: this.maskPIIValue(match[0], piiType)
                });
            }
        }

        // 使用 NLP 模型检测姓名等复杂 PII
        const complexPII = await this.detectComplexPII(text);
        detected_pii.push(...complexPII);

        // 脱敏文本
        const anonymized_text = await this.anonymizeText(text, {
            preserve_format: true,
            masking_strategy: 'partial'
        });

        // 计算风险等级
        const risk_level = this.calculateRiskLevel(detected_pii);

        return {
            detected_pii,
            confidence: this.calculateOverallConfidence(detected_pii),
            anonymized_text,
            risk_level
        };
    }

    async anonymizeText(text: string, options: AnonymizationOptions): Promise<string> {
        let anonymizedText = text;
        const piiResult = await this.detectPII(text);

        // 按位置倒序处理，避免位置偏移
        const sortedPII = piiResult.detected_pii.sort((a, b) =>
            b.position.start - a.position.start
        );

        for (const pii of sortedPII) {
            const maskedValue = options.masking_strategy === 'full'
                ? this.fullMask(pii.value)
                : this.partialMask(pii.value);

            anonymizedText = anonymizedText.substring(0, pii.position.start) +
                           maskedValue +
                           anonymizedText.substring(pii.position.end);
        }

        return anonymizedText;
    }

    private maskPIIValue(value: string, type: PIIType): string {
        switch (type) {
            case PIIType.EMAIL:
                const [local, domain] = value.split('@');
                return `${local.substring(0, 2)}***@${domain}`;

            case PIIType.PHONE:
                return value.replace(/\d(?=\d{4})/g, '*');

            case PIIType.CREDIT_CARD:
                return value.replace(/\d(?=\d{4})/g, '*');

            case PIIType.SSN:
                return value.replace(/\d(?=\d{4})/g, '*');

            default:
                return value.substring(0, 2) + '***' + value.substring(value.length - 2);
        }
    }

    private partialMask(value: string): string {
        if (value.length <= 4) return '***';
        return value.substring(0, 2) + '***' + value.substring(value.length - 2);
    }

    private fullMask(value: string): string {
        return '*'.repeat(value.length);
    }

    private async detectComplexPII(text: string): Promise<PIIEntity[]> {
        // 使用机器学习模型检测姓名、地址等复杂 PII
        // 这里可以集成 spaCy、Stanford NER 等 NLP 工具
        const entities: PIIEntity[] = [];

        // 简化的姓名检测示例
        const namePattern = /\b[A-Z][a-z]+\s+[A-Z][a-z]+\b/g;
        const nameMatches = text.matchAll(namePattern);

        for (const match of nameMatches) {
            entities.push({
                type: PIIType.NAME,
                value: match[0],
                confidence: 0.7, // 较低的置信度，需要人工验证
                position: {
                    start: match.index || 0,
                    end: (match.index || 0) + match[0].length
                },
                masked_value: this.partialMask(match[0])
            });
        }

        return entities;
    }

    private calculateRiskLevel(detected_pii: PIIEntity[]): 'low' | 'medium' | 'high' {
        const highRiskTypes = [PIIType.CREDIT_CARD, PIIType.SSN, PIIType.MEDICAL_RECORD];
        const mediumRiskTypes = [PIIType.EMAIL, PIIType.PHONE, PIIType.ADDRESS];

        if (detected_pii.some(pii => highRiskTypes.includes(pii.type))) {
            return 'high';
        }

        if (detected_pii.some(pii => mediumRiskTypes.includes(pii.type))) {
            return 'medium';
        }

        return detected_pii.length > 0 ? 'low' : 'low';
    }
}
```

### 2. 差分隐私

#### 差分隐私实现
```typescript
interface DifferentialPrivacyService {
    // 添加拉普拉斯噪声
    addLaplaceNoise(value: number, epsilon: number, sensitivity: number): number;

    // 添加高斯噪声
    addGaussianNoise(value: number, epsilon: number, delta: number, sensitivity: number): number;

    // 差分隐私聚合查询
    privateAggregateQuery<T>(
        data: T[],
        query: (data: T[]) => number,
        epsilon: number
    ): Promise<number>;

    // 本地差分隐私
    localDifferentialPrivacy(value: string, epsilon: number): Promise<string>;
}

class DifferentialPrivacyServiceImpl implements DifferentialPrivacyService {
    // 拉普拉斯机制
    addLaplaceNoise(value: number, epsilon: number, sensitivity: number): number {
        const scale = sensitivity / epsilon;
        const noise = this.generateLaplaceNoise(0, scale);
        return value + noise;
    }

    // 高斯机制
    addGaussianNoise(
        value: number,
        epsilon: number,
        delta: number,
        sensitivity: number
    ): number {
        const sigma = this.calculateGaussianSigma(epsilon, delta, sensitivity);
        const noise = this.generateGaussianNoise(0, sigma * sigma);
        return value + noise;
    }

    // 差分隐私计数查询
    async privateCountQuery(
        data: any[],
        condition: (item: any) => boolean,
        epsilon: number
    ): Promise<number> {
        const trueCount = data.filter(condition).length;
        const sensitivity = 1; // 添加或删除一个记录最多改变计数1

        return this.addLaplaceNoise(trueCount, epsilon, sensitivity);
    }

    // 差分隐私平均值查询
    async privateAverageQuery(
        data: number[],
        epsilon: number,
        bounds: [number, number] = [0, 100]
    ): Promise<number> {
        // 裁剪数据到指定范围
        const clippedData = data.map(value =>
            Math.max(bounds[0], Math.min(bounds[1], value))
        );

        const trueAverage = clippedData.reduce((sum, val) => sum + val, 0) / clippedData.length;
        const sensitivity = (bounds[1] - bounds[0]) / clippedData.length;

        return this.addLaplaceNoise(trueAverage, epsilon, sensitivity);
    }

    // 本地差分隐私用于文本数据
    async localDifferentialPrivacy(text: string, epsilon: number): Promise<string> {
        // 将文本转换为数值特征
        const features = this.extractTextFeatures(text);

        // 对每个特征添加噪声
        const noisyFeatures = features.map(feature =>
            this.addLaplaceNoise(feature, epsilon / features.length, 1)
        );

        // 重构文本 (简化实现)
        return this.reconstructTextFromFeatures(noisyFeatures);
    }

    private generateLaplaceNoise(mean: number, scale: number): number {
        const u = Math.random() - 0.5;
        return mean - scale * Math.sign(u) * Math.log(1 - 2 * Math.abs(u));
    }

    private generateGaussianNoise(mean: number, variance: number): number {
        // Box-Muller 变换
        const u1 = Math.random();
        const u2 = Math.random();
        const z0 = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
        return mean + Math.sqrt(variance) * z0;
    }

    private calculateGaussianSigma(epsilon: number, delta: number, sensitivity: number): number {
        // 从 (ε, δ)-DP 计算高斯机制的标准差
        return sensitivity * Math.sqrt(2 * Math.log(1.25 / delta)) / epsilon;
    }

    private extractTextFeatures(text: string): number[] {
        // 简化的文本特征提取
        const features: number[] = [];

        // 文本长度
        features.push(text.length);

        // 大写字母比例
        const upperCaseRatio = (text.match(/[A-Z]/g) || []).length / text.length;
        features.push(upperCaseRatio);

        // 数字比例
        const digitRatio = (text.match(/\d/g) || []).length / text.length;
        features.push(digitRatio);

        // 特殊字符比例
        const specialCharRatio = (text.match(/[^a-zA-Z0-9\s]/g) || []).length / text.length;
        features.push(specialCharRatio);

        return features;
    }

    private reconstructTextFromFeatures(features: number[]): string {
        // 简化的文本重构 (实际应用中需要更复杂的机制)
        const [length, upperRatio, digitRatio, specialRatio] = features;

        // 添加噪声后的长度可能为负数，需要处理
        const safeLength = Math.max(1, Math.round(length));

        // 生成占位符文本
        return `[${safeLength} chars, ${Math.round(upperRatio * 100)}% upper, ${Math.round(digitRatio * 100)}% digits]`;
    }
}

// 使用示例
class StatisticsService {
    constructor(
        private dpService: DifferentialPrivacyService,
        private epsilon: number = 1.0
    ) {}

    async getPrivateUserStats(user_data: UserData[]): Promise<PrivateUserStats> {
        // 差分隐私用户数量
        const userCount = await this.dpService.privateCountQuery(
            user_data,
            (user) => user.is_active,
            this.epsilon * 0.3
        );

        // 差分隐私平均年龄
        const averageAge = await this.dpService.privateAverageQuery(
            user_data.filter(u => u.age).map(u => u.age),
            this.epsilon * 0.3,
            [0, 120] // 年龄范围
        );

        // 差分隐私地区分布 (简化)
        const regionCounts = await this.getPrivateRegionCounts(user_data, this.epsilon * 0.4);

        return {
            user_count: Math.max(0, Math.round(userCount)),
            average_age: Math.max(0, Math.min(120, averageAge)),
            region_distribution: regionCounts
        };
    }
}
```

## 📋 合规性与审计

### 1. GDPR 合规

#### 数据主体权利实现
```typescript
interface GDPRService {
    // 数据访问权
    getDataSubjectAccessRequest(user_id: string): Promise<DataAccessReport>;

    // 数据删除权 (被遗忘权)
    executeRightToBeForgotten(user_id: string): Promise<ErasureReport>;

    // 数据可携带权
    exportUserData(user_id: string, format: 'json' | 'csv' | 'xml'): Promise<PortableData>;

    // 处理限制权
    restrictProcessing(user_id: string, grounds: RestrictionGrounds): Promise<void>;

    // 撤回同意
    withdrawConsent(user_id: string, consent_purpose: string): Promise<void>;
}

interface DataAccessReport {
    user_id: string;
    personal_data: PersonalDataRecord[];
    processing_purposes: string[];
    data_recipients: DataRecipient[];
    retention_periods: RetentionPeriod[];
    legal_basis: LegalBasis[];
    generated_at: Date;
}

interface ErasureReport {
    user_id: string;
    deleted_records: DeletedRecord[];
    retained_records: RetainedRecord[]; // 因法律义务需要保留的记录
    anonymized_records: AnonymizedRecord[];
    completion_timestamp: Date;
}

// GDPR 服务实现
class GDPRServiceImpl implements GDPRService {
    constructor(
        private userRepository: UserRepository,
        private auditLogger: AuditLogger,
        private dataRetentionService: DataRetentionService
    ) {}

    async getDataSubjectAccessRequest(user_id: string): Promise<DataAccessReport> {
        // 记录访问请求
        await this.auditLogger.log({
            event_type: 'data_access_request',
            user_id,
            timestamp: new Date(),
            ip_address: this.getClientIP(),
            user_agent: this.getUserAgent()
        });

        // 收集用户的所有个人数据
        const personalData = await this.collectAllPersonalData(user_id);

        // 确定处理目的
        const processingPurposes = await this.getProcessingPurposes(user_id);

        // 识别数据接收者
        const dataRecipients = await this.getDataRecipients(user_id);

        // 检查保留期限
        const retentionPeriods = await this.getRetentionPeriods(user_id);

        // 确定法律依据
        const legalBasis = await this.getLegalBasis(user_id);

        return {
            user_id,
            personal_data,
            processing_purposes: processingPurposes,
            data_recipients: dataRecipients,
            retention_periods: retentionPeriods,
            legal_basis: legalBasis,
            generated_at: new Date()
        };
    }

    async executeRightToBeForgotten(user_id: string): Promise<ErasureReport> {
        const erasureReport: ErasureReport = {
            user_id,
            deleted_records: [],
            retained_records: [],
            anonymized_records: [],
            completion_timestamp: new Date()
        };

        try {
            // 开始事务
            await this.database.beginTransaction();

            // 识别所有相关数据
            const userData = await this.collectAllPersonalData(user_id);

            for (const record of userData) {
                if (this.canDeleteRecord(record)) {
                    // 可以直接删除的记录
                    await this.deleteRecord(record.id, record.table);
                    erasureReport.deleted_records.push({
                        record_id: record.id,
                        table: record.table,
                        deleted_at: new Date()
                    });
                } else if (this.canAnonymizeRecord(record)) {
                    // 需要匿名化的记录
                    await this.anonymizeRecord(record.id, record.table);
                    erasureReport.anonymized_records.push({
                        record_id: record.id,
                        table: record.table,
                        anonymized_at: new Date()
                    });
                } else {
                    // 因法律义务需要保留的记录
                    erasureReport.retained_records.push({
                        record_id: record.id,
                        table: record.table,
                        retention_reason: record.retention_reason,
                        retention_expiry: record.retention_expiry
                    });
                }
            }

            // 提交事务
            await this.database.commitTransaction();

            // 记录删除操作
            await this.auditLogger.log({
                event_type: 'right_to_be_forgotten_executed',
                user_id,
                deleted_count: erasureReport.deleted_records.length,
                anonymized_count: erasureReport.anonymized_records.length,
                retained_count: erasureReport.retained_records.length,
                timestamp: new Date()
            });

            return erasureReport;

        } catch (error) {
            await this.database.rollbackTransaction();
            throw new Error(`GDPR deletion failed: ${error.message}`);
        }
    }

    async exportUserData(user_id: string, format: 'json' | 'csv' | 'xml'): Promise<PortableData> {
        const userData = await this.collectAllPersonalData(user_id);

        let exportedData: string;
        let mimeType: string;

        switch (format) {
            case 'json':
                exportedData = JSON.stringify(userData, null, 2);
                mimeType = 'application/json';
                break;
            case 'csv':
                exportedData = this.convertToCSV(userData);
                mimeType = 'text/csv';
                break;
            case 'xml':
                exportedData = this.convertToXML(userData);
                mimeType = 'application/xml';
                break;
            default:
                throw new Error(`Unsupported export format: ${format}`);
        }

        return {
            data: exportedData,
            format,
            mime_type: mimeType,
            filename: `user_data_${user_id}_${Date.now()}.${format}`,
            exported_at: new Date()
        };
    }

    private async collectAllPersonalData(user_id: string): Promise<PersonalDataRecord[]> {
        const personalData: PersonalDataRecord[] = [];

        // 用户基本信息
        const userInfo = await this.userRepository.findById(user_id);
        if (userInfo) {
            personalData.push({
                id: userInfo.id,
                table: 'users',
                data: userInfo,
                sensitivity: 'high',
                legal_basis: userInfo.consent_given ? 'consent' : 'legitimate_interest'
            });
        }

        // 用户档案
        const userProfile = await this.userProfileRepository.findByUserId(user_id);
        if (userProfile) {
            personalData.push({
                id: userProfile.id,
                table: 'user_profiles',
                data: userProfile,
                sensitivity: 'high',
                legal_basis: 'consent'
            });
        }

        // 角色相关数据
        const characters = await this.characterRepository.findByUserId(user_id);
        for (const character of characters) {
            personalData.push({
                id: character.id,
                table: 'characters',
                data: character,
                sensitivity: 'medium',
                legal_basis: 'consent'
            });
        }

        // 对话历史
        const conversations = await this.conversationRepository.findByUserId(user_id);
        for (const conversation of conversations) {
            personalData.push({
                id: conversation.id,
                table: 'conversations',
                data: conversation,
                sensitivity: 'high',
                legal_basis: 'consent'
            });
        }

        return personalData;
    }

    private canDeleteRecord(record: PersonalDataRecord): boolean {
        // 检查是否可以删除记录
        return !this.hasLegalObligationToRetain(record) &&
               !this.isWithinRetentionPeriod(record);
    }

    private canAnonymizeRecord(record: PersonalDataRecord): boolean {
        // 检查是否可以匿名化记录
        return this.hasLegalObligationToRetain(record) &&
               record.sensitivity !== 'critical';
    }

    private hasLegalObligationToRetain(record: PersonalDataRecord): boolean {
        // 检查是否有法律义务保留数据
        // 例如：财务记录、安全日志等
        return ['transactions', 'audit_logs', 'security_events'].includes(record.table);
    }

    private isWithinRetentionPeriod(record: PersonalDataRecord): boolean {
        // 检查是否在保留期限内
        const retentionPeriod = this.dataRetentionService.getRetentionPeriod(record.table);
        const expiryDate = new Date(record.data.created_at);
        expiryDate.setFullYear(expiryDate.getFullYear() + retentionPeriod.years);
        expiryDate.setMonth(expiryDate.getMonth() + retentionPeriod.months);
        expiryDate.setDate(expiryDate.getDate() + retentionPeriod.days);

        return new Date() < expiryDate;
    }
}
```

### 2. 安全审计

#### 审计日志系统
```typescript
interface AuditLogger {
    // 记录安全事件
    logSecurityEvent(event: SecurityEvent): Promise<void>;

    // 记录数据访问
    logDataAccess(event: DataAccessEvent): Promise<void>;

    // 记录系统变更
    logSystemChange(event: SystemChangeEvent): Promise<void>;

    // 查询审计日志
    queryAuditLogs(query: AuditLogQuery): Promise<AuditLog[]>;

    // 生成合规报告
    generateComplianceReport(period: ReportPeriod): Promise<ComplianceReport>;
}

interface SecurityEvent {
    event_id: string;
    event_type: SecurityEventType;
    severity: 'low' | 'medium' | 'high' | 'critical';
    user_id?: string;
    ip_address: string;
    user_agent?: string;
    resource_affected?: string;
    description: string;
    details: Record<string, any>;
    timestamp: Date;
    outcome: 'success' | 'failure' | 'partial';
}

enum SecurityEventType {
    LOGIN_SUCCESS = 'login_success',
    LOGIN_FAILURE = 'login_failure',
    LOGOUT = 'logout',
    PASSWORD_CHANGE = 'password_change',
    MFA_ENABLED = 'mfa_enabled',
    MFA_DISABLED = 'mfa_disabled',
    PERMISSION_GRANTED = 'permission_granted',
    PERMISSION_REVOKED = 'permission_revoked',
    DATA_EXPORT = 'data_export',
    DATA_DELETION = 'data_deletion',
    SUSPICIOUS_ACTIVITY = 'suspicious_activity',
    SECURITY_BREACH = 'security_breach'
}

// 审计日志实现
class AuditLoggerImpl implements AuditLogger {
    constructor(
        private database: Database,
        private encryptionService: EncryptionService
    ) {}

    async logSecurityEvent(event: SecurityEvent): Promise<void> {
        // 加密敏感数据
        const encryptedEvent = await this.encryptSensitiveEventData(event);

        // 存储审计日志
        await this.database.query(`
            INSERT INTO audit_logs (
                id, event_type, severity, user_id, ip_address,
                user_agent, resource_affected, description,
                details, timestamp, outcome, encrypted_data
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        `, [
            event.event_id,
            event.event_type,
            event.severity,
            event.user_id,
            event.ip_address,
            event.user_agent,
            event.resource_affected,
            event.description,
            JSON.stringify(event.details),
            event.timestamp,
            event.outcome,
            JSON.stringify(encryptedEvent)
        ]);

        // 高危事件的实时告警
        if (event.severity === 'critical' || event.severity === 'high') {
            await this.triggerSecurityAlert(event);
        }
    }

    async logDataAccess(event: DataAccessEvent): Promise<void> {
        const auditRecord: AuditRecord = {
            id: crypto.randomUUID(),
            event_type: 'data_access',
            user_id: event.user_id,
            resource_type: event.resource_type,
            resource_id: event.resource_id,
            action: event.action,
            ip_address: event.ip_address,
            timestamp: new Date(),
            success: event.success,
            details: {
                query_params: event.query_params,
                fields_accessed: event.fields_accessed,
                record_count: event.record_count
            }
        };

        await this.logSecurityEvent({
            event_id: auditRecord.id,
            event_type: SecurityEventType.DATA_EXPORT,
            severity: 'medium',
            user_id: event.user_id,
            ip_address: event.ip_address,
            resource_affected: `${event.resource_type}:${event.resource_id}`,
            description: `Data access: ${event.action} on ${event.resource_type}`,
            details: auditRecord.details,
            timestamp: auditRecord.timestamp,
            outcome: event.success ? 'success' : 'failure'
        });
    }

    async queryAuditLogs(query: AuditLogQuery): Promise<AuditLog[]> {
        let sql = `
            SELECT id, event_type, severity, user_id, ip_address,
                   description, timestamp, outcome, created_at
            FROM audit_logs
            WHERE 1=1
        `;

        const params: any[] = [];
        let paramIndex = 1;

        if (query.user_id) {
            sql += ` AND user_id = $${paramIndex++}`;
            params.push(query.user_id);
        }

        if (query.event_type) {
            sql += ` AND event_type = $${paramIndex++}`;
            params.push(query.event_type);
        }

        if (query.start_date) {
            sql += ` AND timestamp >= $${paramIndex++}`;
            params.push(query.start_date);
        }

        if (query.end_date) {
            sql += ` AND timestamp <= $${paramIndex++}`;
            params.push(query.end_date);
        }

        if (query.severity) {
            sql += ` AND severity = $${paramIndex++}`;
            params.push(query.severity);
        }

        sql += ` ORDER BY timestamp DESC`;

        if (query.limit) {
            sql += ` LIMIT $${paramIndex++}`;
            params.push(query.limit);
        }

        const result = await this.database.query(sql, params);
        return result.rows;
    }

    async generateComplianceReport(period: ReportPeriod): Promise<ComplianceReport> {
        const startDate = period.start_date;
        const endDate = period.end_date;

        // 收集安全事件统计
        const securityEvents = await this.queryAuditLogs({
            start_date: startDate,
            end_date: endDate
        });

        // 数据访问统计
        const dataAccessEvents = securityEvents.filter(event =>
            event.event_type === 'data_access'
        );

        // 认证事件统计
        const authEvents = securityEvents.filter(event =>
            ['login_success', 'login_failure', 'logout'].includes(event.event_type)
        );

        // 高危事件统计
        const highSeverityEvents = securityEvents.filter(event =>
            ['high', 'critical'].includes(event.severity)
        );

        return {
            period,
            total_events: securityEvents.length,
            security_incidents: highSeverityEvents.length,
            data_access_requests: dataAccessEvents.length,
            authentication_events: authEvents.length,
            failed_login_attempts: authEvents.filter(e => e.event_type === 'login_failure').length,
            unique_users: [...new Set(securityEvents.map(e => e.user_id).filter(Boolean))].length,
            top_ip_addresses: this.getTopIPAddresses(securityEvents),
            compliance_status: this.assessComplianceStatus(securityEvents),
            recommendations: this.generateRecommendations(securityEvents)
        };
    }

    private async encryptSensitiveEventData(event: SecurityEvent): Promise<any> {
        const sensitiveFields = ['user_agent', 'details'];
        const encrypted: any = {};

        for (const field of sensitiveFields) {
            if (event[field as keyof SecurityEvent]) {
                encrypted[field] = await this.encryptionService.encrypt(
                    JSON.stringify(event[field as keyof SecurityEvent])
                );
            }
        }

        return encrypted;
    }

    private async triggerSecurityAlert(event: SecurityEvent): Promise<void> {
        // 发送安全告警到监控系统
        const alert = {
            alert_type: 'security_event',
            severity: event.severity,
            event_id: event.event_id,
            description: event.description,
            timestamp: event.timestamp,
            requires_immediate_action: event.severity === 'critical'
        };

        await this.alertingService.sendAlert(alert);
    }

    private getTopIPAddresses(events: AuditLog[]): Array<{ ip: string; count: number }> {
        const ipCounts = events.reduce((acc, event) => {
            acc[event.ip_address] = (acc[event.ip_address] || 0) + 1;
            return acc;
        }, {} as Record<string, number>);

        return Object.entries(ipCounts)
            .map(([ip, count]) => ({ ip, count }))
            .sort((a, b) => b.count - a.count)
            .slice(0, 10);
    }

    private assessComplianceStatus(events: AuditLog[]): 'compliant' | 'warning' | 'non_compliant' {
        const criticalEvents = events.filter(e => e.severity === 'critical').length;
        const failedLogins = events.filter(e => e.event_type === 'login_failure').length;
        const totalEvents = events.length;

        if (criticalEvents > 0 || failedLogins / totalEvents > 0.1) {
            return 'non_compliant';
        }

        if (failedLogins / totalEvents > 0.05) {
            return 'warning';
        }

        return 'compliant';
    }

    private generateRecommendations(events: AuditLog[]): string[] {
        const recommendations: string[] = [];

        const failureRate = events.filter(e => e.outcome === 'failure').length / events.length;
        if (failureRate > 0.1) {
            recommendations.push('建议审查失败率高的操作，可能存在安全问题');
        }

        const highSeverityRate = events.filter(e => ['high', 'critical'].includes(e.severity)).length / events.length;
        if (highSeverityRate > 0.05) {
            recommendations.push('高危事件比例较高，建议加强安全防护措施');
        }

        const uniqueIPs = [...new Set(events.map(e => e.ip_address))].length;
        if (uniqueIPs > events.length * 0.8) {
            recommendations.push('IP地址分散度较高，建议加强访问控制');
        }

        return recommendations;
    }
}
```

---

_文档版本: v1.0_
_最后更新: 2024-11-10_
_维护者: AI开发团队_

这份安全与隐私保护指南为AI系统提供了全面的安全框架，涵盖了从基础设施到应用层的各个安全层面，确保系统在提供智能服务的同时保护用户数据和隐私权益。