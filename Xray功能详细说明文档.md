# Xray 功能详细说明文档

## 目录
1. [出站规则功能详细说明](#出站规则功能详细说明)
2. [反向代理功能详细说明](#反向代理功能详细说明)
3. [负载均衡功能详细说明](#负载均衡功能详细说明)

---

## 出站规则功能详细说明

### 概述
出站规则（Outbound Rules）是 Xray 中用于定义数据包如何离开代理服务器的核心功能。它决定了不同类型的流量应该通过哪种方式、哪个出站连接进行转发。

### 主要参数说明

#### 1. 协议类型 (Protocol)
- **freedom**: 直连协议，数据包直接发送到目标服务器
- **blackhole**: 黑洞协议，丢弃所有数据包
- **dns**: DNS 协议，用于 DNS 查询
- **http**: HTTP 代理协议
- **socks**: SOCKS 代理协议
- **shadowsocks**: Shadowsocks 协议
- **vmess**: VMess 协议
- **vless**: VLESS 协议
- **trojan**: Trojan 协议

#### 2. 标签 (Tag)
- **用途**: 为出站连接分配唯一标识符
- **格式**: 字符串，建议使用有意义的名称
- **示例**: "direct", "proxy", "block", "us-server"

#### 3. 域名策略 (Domain Strategy)
- **AsIs**: 不进行域名解析，直接使用域名
- **UseIP**: 使用 IP 地址进行连接
- **UseIPv4**: 强制使用 IPv4
- **UseIPv6**: 强制使用 IPv6

#### 4. 发送设置 (Send Through)
- **用途**: 指定发送数据时使用的本地 IP 地址
- **适用场景**: 多网卡环境、指定出口 IP

### 实际应用场景

#### 场景1: 分流代理配置
**需求**: 国内网站直连，国外网站走代理

**配置示例**:
```json
{
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIP"
      }
    },
    {
      "tag": "proxy",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "proxy.example.com",
            "port": 443,
            "users": [
              {
                "id": "uuid-here",
                "security": "auto"
              }
            ]
          }
        ]
      }
    },
    {
      "tag": "block",
      "protocol": "blackhole",
      "settings": {}
    }
  ]
}
```

#### 场景2: 多服务器负载均衡
**需求**: 将流量分散到多个代理服务器

**配置示例**:
```json
{
  "outbounds": [
    {
      "tag": "us-server-1",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "us1.example.com",
            "port": 443,
            "users": [{"id": "uuid1", "security": "auto"}]
          }
        ]
      }
    },
    {
      "tag": "us-server-2",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "us2.example.com",
            "port": 443,
            "users": [{"id": "uuid2", "security": "auto"}]
          }
        ]
      }
    }
  ]
}
```

#### 场景3: 广告屏蔽配置
**需求**: 屏蔽广告域名和恶意网站

**配置示例**:
```json
{
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "adblock",
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "http"
        }
      }
    }
  ]
}
```

### 最佳实践

1. **标签命名规范**: 使用有意义的标签名，如 "direct", "proxy-us", "block-ads"
2. **域名策略选择**: 
   - 对于需要 CDN 优化的服务使用 "AsIs"
   - 对于需要精确控制的场景使用 "UseIP"
3. **性能优化**: 合理配置 `domainStrategy` 以减少 DNS 查询延迟
4. **安全考虑**: 使用黑洞协议屏蔽恶意流量和广告

---

## 反向代理功能详细说明

### 概述
反向代理（Reverse Proxy）功能允许 Xray 作为服务器端代理，接收客户端请求并转发到后端服务器，同时可以对请求和响应进行处理和优化。

### 主要参数说明

#### 1. 监听配置 (Listen)
- **address**: 监听地址，如 "0.0.0.0" 或 "127.0.0.1"
- **port**: 监听端口号
- **protocol**: 协议类型（http, https, tcp, udp）

#### 2. 目标配置 (Destination)
- **address**: 后端服务器地址
- **port**: 后端服务器端口
- **network**: 网络类型（tcp, udp, unix）

#### 3. 传输配置 (Transport)
- **type**: 传输类型（tcp, ws, h2, grpc）
- **security**: 安全设置（none, tls）
- **headers**: HTTP 头部设置

#### 4. 路由配置 (Routing)
- **path**: URL 路径匹配
- **host**: 主机名匹配
- **method**: HTTP 方法匹配

### 实际应用场景

#### 场景1: Web 服务反向代理
**需求**: 为内网 Web 服务提供外网访问

**配置示例**:
```json
{
  "inbounds": [
    {
      "tag": "web-proxy",
      "port": 80,
      "protocol": "http",
      "settings": {
        "timeout": 300,
        "accounts": []
      }
    }
  ],
  "outbounds": [
    {
      "tag": "web-backend",
      "protocol": "freedom",
      "settings": {
        "redirect": "192.168.1.100:8080"
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": ["web-proxy"],
        "outboundTag": "web-backend"
      }
    ]
  }
}
```

#### 场景2: HTTPS 终端代理
**需求**: 处理 SSL/TLS 加密，转发到内网 HTTP 服务

**配置示例**:
```json
{
  "inbounds": [
    {
      "tag": "https-proxy",
      "port": 443,
      "protocol": "http",
      "settings": {},
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/path/to/cert.pem",
              "keyFile": "/path/to/key.pem"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "http-backend",
      "protocol": "freedom",
      "settings": {
        "redirect": "127.0.0.1:8080"
      }
    }
  ]
}
```

#### 场景3: API 网关代理
**需求**: 根据路径将请求转发到不同的后端服务

**配置示例**:
```json
{
  "inbounds": [
    {
      "tag": "api-gateway",
      "port": 8080,
      "protocol": "http",
      "settings": {}
    }
  ],
  "outbounds": [
    {
      "tag": "user-service",
      "protocol": "freedom",
      "settings": {
        "redirect": "192.168.1.10:3000"
      }
    },
    {
      "tag": "order-service",
      "protocol": "freedom",
      "settings": {
        "redirect": "192.168.1.11:3000"
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": ["api-gateway"],
        "domain": ["api.example.com"],
        "path": ["/api/users/*"],
        "outboundTag": "user-service"
      },
      {
        "type": "field",
        "inboundTag": ["api-gateway"],
        "domain": ["api.example.com"],
        "path": ["/api/orders/*"],
        "outboundTag": "order-service"
      }
    ]
  }
}
```

### 最佳实践

1. **性能优化**:
   - 启用 HTTP/2 以提高并发性能
   - 合理设置超时时间
   - 使用连接池减少连接开销

2. **安全配置**:
   - 配置适当的 TLS 设置
   - 限制访问来源 IP
   - 添加请求头验证

3. **监控和日志**:
   - 启用访问日志记录
   - 配置健康检查
   - 监控后端服务状态

---

## 负载均衡功能详细说明

### 概述
负载均衡（Load Balancing）功能允许 Xray 将流量分散到多个后端服务器，提高系统的可用性、可靠性和性能。

### 主要参数说明

#### 1. 均衡器配置 (Balancer)
- **tag**: 均衡器标识符
- **selector**: 出站连接选择器
- **strategy**: 负载均衡策略

#### 2. 负载均衡策略 (Strategy)
- **random**: 随机选择
- **round_robin**: 轮询选择
- **least_ping**: 选择延迟最低的服务器
- **least_load**: 选择负载最低的服务器

#### 3. 健康检查 (Health Check)
- **enabled**: 是否启用健康检查
- **interval**: 检查间隔时间
- **timeout**: 检查超时时间
- **destination**: 检查目标地址

#### 4. 故障转移 (Failover)
- **enabled**: 是否启用故障转移
- **threshold**: 故障阈值
- **recovery**: 恢复策略

### 实际应用场景

#### 场景1: 多服务器代理负载均衡
**需求**: 将用户流量分散到多个代理服务器

**配置示例**:
```json
{
  "outbounds": [
    {
      "tag": "proxy-us-1",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "us1.example.com",
            "port": 443,
            "users": [{"id": "uuid1", "security": "auto"}]
          }
        ]
      }
    },
    {
      "tag": "proxy-us-2",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "us2.example.com",
            "port": 443,
            "users": [{"id": "uuid2", "security": "auto"}]
          }
        ]
      }
    },
    {
      "tag": "proxy-us-3",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "us3.example.com",
            "port": 443,
            "users": [{"id": "uuid3", "security": "auto"}]
          }
        ]
      }
    }
  ],
  "routing": {
    "balancers": [
      {
        "tag": "us-balancer",
        "selector": ["proxy-us-1", "proxy-us-2", "proxy-us-3"],
        "strategy": {
          "type": "leastPing"
        }
      }
    ],
    "rules": [
      {
        "type": "field",
        "network": "tcp,udp",
        "balancerTag": "us-balancer"
      }
    ]
  }
}
```

#### 场景2: 地理位置负载均衡
**需求**: 根据目标地址选择最优的出站服务器

**配置示例**:
```json
{
  "outbounds": [
    {
      "tag": "asia-server",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "asia.example.com",
            "port": 443,
            "users": [{"id": "uuid-asia", "security": "auto"}]
          }
        ]
      }
    },
    {
      "tag": "europe-server",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "europe.example.com",
            "port": 443,
            "users": [{"id": "uuid-europe", "security": "auto"}]
          }
        ]
      }
    },
    {
      "tag": "america-server",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "america.example.com",
            "port": 443,
            "users": [{"id": "uuid-america", "security": "auto"}]
          }
        ]
      }
    }
  ],
  "routing": {
    "balancers": [
      {
        "tag": "asia-balancer",
        "selector": ["asia-server"],
        "strategy": {
          "type": "random"
        }
      },
      {
        "tag": "global-balancer",
        "selector": ["europe-server", "america-server"],
        "strategy": {
          "type": "leastPing"
        }
      }
    ],
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:cn", "geoip:jp", "geoip:kr"],
        "balancerTag": "asia-balancer"
      },
      {
        "type": "field",
        "network": "tcp,udp",
        "balancerTag": "global-balancer"
      }
    ]
  }
}
```

#### 场景3: 故障转移负载均衡
**需求**: 主服务器故障时自动切换到备用服务器

**配置示例**:
```json
{
  "outbounds": [
    {
      "tag": "primary-server",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "primary.example.com",
            "port": 443,
            "users": [{"id": "uuid-primary", "security": "auto"}]
          }
        ]
      }
    },
    {
      "tag": "backup-server-1",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "backup1.example.com",
            "port": 443,
            "users": [{"id": "uuid-backup1", "security": "auto"}]
          }
        ]
      }
    },
    {
      "tag": "backup-server-2",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "backup2.example.com",
            "port": 443,
            "users": [{"id": "uuid-backup2", "security": "auto"}]
          }
        ]
      }
    }
  ],
  "routing": {
    "balancers": [
      {
        "tag": "failover-balancer",
        "selector": ["primary-server", "backup-server-1", "backup-server-2"],
        "strategy": {
          "type": "leastPing"
        },
        "fallbackTag": "backup-server-1"
      }
    ],
    "rules": [
      {
        "type": "field",
        "network": "tcp,udp",
        "balancerTag": "failover-balancer"
      }
    ]
  }
}
```

### 负载均衡策略详解

#### 1. Random（随机）
- **特点**: 随机选择可用的出站连接
- **适用场景**: 服务器性能相近，简单分散负载
- **优点**: 实现简单，分布相对均匀
- **缺点**: 可能出现短期内负载不均

#### 2. Round Robin（轮询）
- **特点**: 按顺序轮流选择出站连接
- **适用场景**: 服务器性能相近，需要均匀分配
- **优点**: 负载分配均匀
- **缺点**: 不考虑服务器实际负载情况

#### 3. Least Ping（最低延迟）
- **特点**: 选择延迟最低的服务器
- **适用场景**: 对延迟敏感的应用
- **优点**: 提供最佳用户体验
- **缺点**: 可能导致某些服务器负载过高

#### 4. Least Load（最低负载）
- **特点**: 选择当前负载最低的服务器
- **适用场景**: 服务器性能差异较大
- **优点**: 充分利用服务器资源
- **缺点**: 需要实时监控服务器状态

### 最佳实践

1. **策略选择**:
   - 性能相近的服务器使用轮询或随机
   - 性能差异大的服务器使用最低负载
   - 对延迟敏感的应用使用最低延迟

2. **健康检查**:
   - 启用定期健康检查
   - 设置合理的检查间隔和超时时间
   - 配置故障恢复机制

3. **监控和维护**:
   - 监控各服务器的负载和响应时间
   - 定期检查配置的有效性
   - 根据实际使用情况调整策略

4. **安全考虑**:
   - 确保所有服务器的安全配置一致
   - 定期更新服务器证书和密钥
   - 监控异常流量和访问模式

---

## 总结

本文档详细介绍了 Xray 的三个核心功能：出站规则、反向代理和负载均衡。每个功能都提供了完整的参数说明、实际应用场景和最佳实践建议。

通过合理配置这些功能，可以构建高性能、高可用的网络代理系统，满足各种复杂的网络需求。建议在实际部署时，根据具体的业务需求和网络环境，选择合适的配置方案。

对于初学者，建议从简单的配置开始，逐步学习和掌握各项功能。对于高级用户，可以结合多种功能创建复杂的网络拓扑，实现更精细的流量控制和优化。