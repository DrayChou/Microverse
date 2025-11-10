# AI 系统性能优化与监控指南

## 📋 概述

本文档详细描述了 AI 驱动虚拟世界系统的性能优化策略、监控体系和故障排除方法。涵盖了从前端到后端、从应用到基础设施的全方位性能管理方案。

## 🎯 性能优化架构概览

### 1. 性能优化层次结构

```
┌─────────────────────────────────────────────────────────────────┐
│                   前端性能优化 (Frontend)                       │
├─────────────────────────────────────────────────────────────────┤
│  代码分割  │  缓存策略  │  资源优化  │  渲染优化               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   网络层优化 (Network)                         │
├─────────────────────────────────────────────────────────────────┤
│  CDN加速  │  压缩传输  │  连接复用  │  请求优化               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   后端性能优化 (Backend)                          │
├─────────────────────────────────────────────────────────────────┤
│  数据库优化  │  缓存层  │  异步处理  │  资源池               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   AI 模型优化 (AI Models)                         │
├─────────────────────────────────────────────────────────────────┤
│  模型量化  │  推理优化  │  批处理  │  智能路由               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 基础设施优化 (Infrastructure)                     │
├─────────────────────────────────────────────────────────────────┤
│  容器优化  │  负载均衡  │  自动扩展  │  资源调度               │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 前端性能优化

### 1. 代码分割与懒加载

#### React/Vue 代码分割配置
```typescript
// src/routes/index.ts - React Router 代码分割
import { lazy, Suspense } from 'react';
import { createBrowserRouter, RouterProvider, Route } from 'react-router-dom';
import LoadingSpinner from '../components/LoadingSpinner';

// 懒加载组件
const Dashboard = lazy(() => import('../pages/Dashboard'));
const CharacterEditor = lazy(() => import('../pages/CharacterEditor'));
const AIConfiguration = lazy(() => import('../pages/AIConfiguration'));
const WorldView = lazy(() => import('../pages/WorldView'));

const AppRouter = () => {
  const router = createBrowserRouter([
    {
      path: '/',
      element: <Suspense fallback={<LoadingSpinner />}><Dashboard /></Suspense>
    },
    {
      path: '/characters/:id/edit',
      element: <Suspense fallback={<LoadingSpinner />}><CharacterEditor /></Suspense>
    },
    {
      path: '/ai/config',
      element: <Suspense fallback={<LoadingSpinner />}><AIConfiguration /></Suspense>
    },
    {
      path: '/world',
      element: <Suspense fallback={<LoadingSpinner />}><WorldView /></Suspense>
    }
  ]);

  return <RouterProvider router={router} />;
};

export default AppRouter;
```

#### Vue 3 动态导入配置
```typescript
// src/router/index.ts
import { createRouter, createWebHistory } from 'vue-router';

const routes = [
  {
    path: '/',
    name: 'Dashboard',
    component: () => import('../views/Dashboard.vue')
  },
  {
    path: '/characters/:id/edit',
    name: 'CharacterEditor',
    component: () => import('../views/CharacterEditor.vue')
  },
  {
    path: '/ai/config',
    name: 'AIConfiguration',
    component: () => import('../views/AIConfiguration.vue')
  },
  {
    path: '/world',
    name: 'WorldView',
    component: () => import('../views/WorldView.vue')
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

export default router;
```

### 2. 资源优化与缓存

#### 资源预加载策略
```typescript
// src/utils/resourcePreloader.ts
class ResourcePreloader {
  private preloadedResources = new Map<string, boolean>();
  private preloadQueue: Array<() => Promise<any>> = [];

  // 预加载关键资源
  preloadCriticalResources(): void {
    const criticalResources = [
      () => this.preloadImage('/assets/ui/character-avatar.png'),
      () => this.preloadFont('/assets/fonts/main.woff2'),
      () => this.preloadScript('/js/ai-worker.js'),
      () => this.preloadStylesheet('/css/main.css')
    ];

    this.preloadQueue.push(...criticalResources);
    this.processPreloadQueue();
  }

  // 预加载图片
  preloadImage(src: string): Promise<HTMLImageElement> {
    return new Promise((resolve, reject) => {
      if (this.preloadedResources.has(src)) {
        resolve(new Image());
        return;
      }

      const img = new Image();
      img.onload = () => {
        this.preloadedResources.set(src, true);
        resolve(img);
      };
      img.onerror = reject;
      img.src = src;
    });
  }

  // 预加载字体
  preloadFont(src: string): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.preloadedResources.has(src)) {
        resolve();
        return;
      }

      const font = new FontFace('MainFont', `url(${src})`);
      font.load().then(() => {
        (document.fonts as any).add(font);
        this.preloadedResources.set(src, true);
        resolve();
      }).catch(reject);
    });
  }

  // 预加载脚本
  preloadScript(src: string): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.preloadedResources.has(src)) {
        resolve();
        return;
      }

      const script = document.createElement('script');
      script.onload = () => {
        this.preloadedResources.set(src, true);
        resolve();
      };
      script.onerror = reject;
      script.src = src;
      document.head.appendChild(script);
    });
  }

  // 预加载样式表
  preloadStylesheet(href: string): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.preloadedResources.has(href)) {
        resolve();
        return;
      }

      const link = document.createElement('link');
      link.rel = 'preload';
      link.as = 'style';
      link.onload = () => {
        this.preloadedResources.set(href, true);
        resolve();
      };
      link.onerror = reject;
      link.href = href;
      document.head.appendChild(link);
    });
  }

  // 处理预加载队列
  private async processPreloadQueue(): Promise<void> {
    const BATCH_SIZE = 3; // 并发预加载数量

    while (this.preloadQueue.length > 0) {
      const batch = this.preloadQueue.splice(0, BATCH_SIZE);

      try {
        await Promise.all(batch.map(task => task()));
      } catch (error) {
        console.warn('Preload batch failed:', error);
      }
    }
  }

  // 智能预加载 (基于用户行为)
  intelligentPreload(userBehavior: UserBehaviorData): void {
    const predictions = this.predictNextResources(userBehavior);

    predictions.forEach(resource => {
      if (!this.preloadedResources.has(resource)) {
        this.preloadQueue.push(() => this.preloadResource(resource));
      }
    });

    this.processPreloadQueue();
  }

  private predictNextResources(userBehavior: UserBehaviorData): string[] {
    const predictions: string[] = [];

    // 基于用户行为模式预测
    if (userBehavior.lastPage === '/characters') {
      predictions.push('/assets/character-editor-bg.jpg');
      predictions.push('/assets/icons/character-sprite.png');
    }

    if (userBehavior.interactionPattern === 'ai-heavy') {
      predictions.push('/js/ai-optimization.js');
      predictions.push('/assets/ai-thinking.gif');
    }

    return predictions;
  }

  private async preloadResource(src: string): Promise<void> {
    if (src.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
      await this.preloadImage(src);
    } else if (src.match(/\.(woff|woff2|ttf|eot)$/i)) {
      await this.preloadFont(src);
    } else if (src.match(/\.js$/i)) {
      await this.preloadScript(src);
    } else if (src.match(/\.css$/i)) {
      await this.preloadStylesheet(src);
    }
  }
}

// 用户行为数据收集
interface UserBehaviorData {
  lastPage: string;
  interactionPattern: string;
  timeSpentOnPage: number;
  clickPatterns: Array<{ element: string; timestamp: number }>;
  scrollPatterns: Array<{ depth: number; timestamp: number }>;
}

export default ResourcePreloader;
```

#### 缓存策略实现
```typescript
// src/utils/cacheManager.ts
interface CacheEntry<T> {
  data: T;
  timestamp: number;
  expiresAt: number;
  accessCount: number;
  lastAccessed: number;
}

class CacheManager {
  private cache = new Map<string, CacheEntry<any>>();
  private maxSize: number;
  private defaultTTL: number;

  constructor(maxSize = 100, defaultTTL = 300000) { // 5 minutes default TTL
    this.maxSize = maxSize;
    this.defaultTTL = defaultTTL;

    // 定期清理过期缓存
    setInterval(() => this.cleanup(), 60000); // 每分钟清理一次
  }

  // 设置缓存
  set<T>(key: string, data: T, ttl?: number): void {
    const expiresAt = Date.now() + (ttl || this.defaultTTL);

    // 如果缓存已满，清理最久未访问的条目
    if (this.cache.size >= this.maxSize) {
      this.evictLRU();
    }

    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      expiresAt,
      accessCount: 1,
      lastAccessed: Date.now()
    });
  }

  // 获取缓存
  get<T>(key: string): T | null {
    const entry = this.cache.get(key);

    if (!entry) {
      return null;
    }

    // 检查是否过期
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }

    // 更新访问信息
    entry.accessCount++;
    entry.lastAccessed = Date.now();

    return entry.data;
  }

  // 删除缓存
  delete(key: string): boolean {
    return this.cache.delete(key);
  }

  // 清空所有缓存
  clear(): void {
    this.cache.clear();
  }

  // LRU 淘汰策略
  private evictLRU(): void {
    let oldestKey = '';
    let oldestTime = Date.now();

    for (const [key, entry] of this.cache.entries()) {
      if (entry.lastAccessed < oldestTime) {
        oldestTime = entry.lastAccessed;
        oldestKey = key;
      }
    }

    if (oldestKey) {
      this.cache.delete(oldestKey);
    }
  }

  // 清理过期缓存
  private cleanup(): void {
    const now = Date.now();
    const expiredKeys: string[] = [];

    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expiresAt) {
        expiredKeys.push(key);
      }
    }

    expiredKeys.forEach(key => this.cache.delete(key));
  }

  // 获取缓存统计
  getStats(): CacheStats {
    const now = Date.now();
    let totalEntries = 0;
    let expiredEntries = 0;
    let totalAccessCount = 0;
    let averageAge = 0;

    for (const entry of this.cache.values()) {
      totalEntries++;
      totalAccessCount += entry.accessCount;
      averageAge += (now - entry.timestamp);

      if (now > entry.expiresAt) {
        expiredEntries++;
      }
    }

    averageAge = totalEntries > 0 ? averageAge / totalEntries : 0;

    return {
      totalEntries,
      expiredEntries,
      hitRate: this.calculateHitRate(),
      averageAge: Math.round(averageAge),
      averageAccessCount: totalEntries > 0 ? Math.round(totalAccessCount / totalEntries) : 0
    };
  }

  private hitRate = 0;
  private missCount = 0;
  private hitCount = 0;

  updateHitRate(hit: boolean): void {
    if (hit) {
      this.hitCount++;
    } else {
      this.missCount++;
    }

    this.hitRate = this.hitCount / (this.hitCount + this.missCount);
  }

  private calculateHitRate(): number {
    return this.hitRate;
  }
}

// 不同类型的缓存管理器
class APICacheManager extends CacheManager {
  constructor() {
    super(50, 300000); // API 缓存5分钟
  }

  async getWithFallback<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttl?: number
  ): Promise<T> {
    // 尝试从缓存获取
    const cached = this.get<T>(key);
    if (cached !== null) {
      return cached;
    }

    // 缓存未命中，获取数据
    try {
      const data = await fetcher();
      this.set(key, data, ttl);
      return data;
    } catch (error) {
      console.error(`Failed to fetch data for key ${key}:`, error);
      throw error;
    }
  }
}

class ImageCacheManager extends CacheManager {
  constructor() {
    super(100, 3600000); // 图片缓存1小时
  }

  preloadImage(src: string): Promise<HTMLImageElement> {
    const cached = this.get<HTMLImageElement>(src);
    if (cached) {
      return Promise.resolve(cached);
    }

    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => {
        this.set(src, img);
        resolve(img);
      };
      img.onerror = reject;
      img.src = src;
    });
  }
}

export { CacheManager, APICacheManager, ImageCacheManager };
```

### 3. 渲染性能优化

#### 虚拟滚动实现
```typescript
// src/components/VirtualScrollList.tsx
import React, { useState, useEffect, useRef, useMemo } from 'react';

interface VirtualScrollProps<T> {
  items: T[];
  itemHeight: number;
  containerHeight: number;
  renderItem: (item: T, index: number) => React.ReactNode;
  overscan?: number;
}

function VirtualScrollList<T>({
  items,
  itemHeight,
  containerHeight,
  renderItem,
  overscan = 5
}: VirtualScrollProps<T>) {
  const [scrollTop, setScrollTop] = useState(0);
  const scrollElementRef = useRef<HTMLDivElement>(null);

  // 计算可见范围
  const visibleRange = useMemo(() => {
    const startIndex = Math.max(0, Math.floor(scrollTop / itemHeight) - overscan);
    const endIndex = Math.min(
      items.length - 1,
      Math.ceil((scrollTop + containerHeight) / itemHeight) + overscan
    );

    return { startIndex, endIndex };
  }, [scrollTop, itemHeight, containerHeight, overscan, items.length]);

  // 可见项目
  const visibleItems = useMemo(() => {
    return items.slice(visibleRange.startIndex, visibleRange.endIndex + 1);
  }, [items, visibleRange]);

  // 处理滚动事件
  const handleScroll = useCallback((e: React.UIEvent<HTMLDivElement>) => {
    setScrollTop(e.currentTarget.scrollTop);
  }, []);

  return (
    <div
      ref={scrollElementRef}
      style={{
        height: containerHeight,
        overflow: 'auto'
      }}
      onScroll={handleScroll}
    >
      <div
        style={{
          height: items.length * itemHeight,
          position: 'relative'
        }}
      >
        {visibleItems.map((item, index) => {
          const actualIndex = visibleRange.startIndex + index;
          const top = actualIndex * itemHeight;

          return (
            <div
              key={actualIndex}
              style={{
                position: 'absolute',
                top,
                left: 0,
                right: 0,
                height: itemHeight
              }}
            >
              {renderItem(item, actualIndex)}
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default VirtualScrollList;
```

#### Canvas 渲染优化
```typescript
// src/utils/canvasRenderer.ts
class CanvasRenderer {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;
  private offscreenCanvas: HTMLCanvasElement;
  private offscreenCtx: CanvasRenderingContext2D;
  private animationFrameId: number | null = null;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d')!;

    // 创建离屏画布
    this.offscreenCanvas = document.createElement('canvas');
    this.offscreenCanvas.width = canvas.width;
    this.offscreenCanvas.height = canvas.height;
    this.offscreenCtx = this.offscreenCanvas.getContext('2d')!;

    // 启用硬件加速
    this.ctx.imageSmoothingEnabled = true;
    this.offscreenCtx.imageSmoothingEnabled = true;
  }

  // 渲染角色精灵
  renderCharacterSprite(
    sprite: HTMLImageElement,
    x: number,
    y: number,
    width: number,
    height: number,
    frame: number = 0
  ): void {
    // 在离屏画布上绘制
    this.offscreenCtx.clearRect(0, 0, this.offscreenCanvas.width, this.offscreenCanvas.height);
    this.offscreenCtx.drawImage(
      sprite,
      frame * width,
      0,
      width,
      height,
      x,
      y,
      width,
      height
    );

    // 批量复制到主画布
    this.ctx.clearRect(x, y, width, height);
    this.ctx.drawImage(this.offscreenCanvas, x, y, width, height, x, y, width, height);
  }

  // 批量渲染多个角色
  renderCharacters(characters: CharacterRenderData[]): void {
    // 清空画布
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    // 按层级排序
    characters.sort((a, b) => a.zIndex - b.zIndex);

    // 批量渲染
    characters.forEach(character => {
      this.renderCharacterSprite(
        character.sprite,
        character.x,
        character.y,
        character.width,
        character.height,
        character.frame
      );
    });
  }

  // 动画循环
  startAnimation(renderCallback: () => CharacterRenderData[]): void {
    const animate = () => {
      const characters = renderCallback();
      this.renderCharacters(characters);
      this.animationFrameId = requestAnimationFrame(animate);
    };

    animate();
  }

  stopAnimation(): void {
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }
  }

  // 调整画布大小
  resize(width: number, height: number): void {
    this.canvas.width = width;
    this.canvas.height = height;
    this.offscreenCanvas.width = width;
    this.offscreenCanvas.height = height;
  }

  // 性能监控
  getPerformanceMetrics(): CanvasPerformanceMetrics {
    return {
      canvasSize: `${this.canvas.width}x${this.canvas.height}`,
      isOffscreenCanvasEnabled: this.offscreenCanvas !== null,
      animationFrameActive: this.animationFrameId !== null,
      estimatedMemoryUsage: this.estimateMemoryUsage()
    };
  }

  private estimateMemoryUsage(): number {
    const canvasSize = this.canvas.width * this.canvas.height * 4; // RGBA
    const offscreenSize = this.offscreenCanvas.width * this.offscreenCanvas.height * 4;
    return canvasSize + offscreenSize;
  }
}

interface CharacterRenderData {
  sprite: HTMLImageElement;
  x: number;
  y: number;
  width: number;
  height: number;
  frame: number;
  zIndex: number;
}

interface CanvasPerformanceMetrics {
  canvasSize: string;
  isOffscreenCanvasEnabled: boolean;
  animationFrameActive: boolean;
  estimatedMemoryUsage: number;
}

export default CanvasRenderer;
```

## 🗄️ 后端性能优化

### 1. 数据库优化

#### 连接池配置
```typescript
// src/database/ConnectionPool.ts
import { Pool, PoolConfig } from 'pg';

interface DatabaseConfig {
  host: string;
  port: number;
  database: string;
  username: string;
  password: string;
  minConnections?: number;
  maxConnections?: number;
  idleTimeoutMillis?: number;
  connectionTimeoutMillis?: number;
}

class DatabaseConnectionPool {
  private pool: Pool;
  private config: PoolConfig;

  constructor(config: DatabaseConfig) {
    this.config = {
      host: config.host,
      port: config.port,
      database: config.database,
      user: config.username,
      password: config.password,
      min: config.minConnections || 5,
      max: config.maxConnections || 20,
      idleTimeoutMillis: config.idleTimeoutMillis || 30000,
      connectionTimeoutMillis: config.connectionTimeoutMillis || 10000,
      // 启用连接保活
      keepAlive: true,
      // SSL 配置
      ssl: process.env.NODE_ENV === 'production',
      // 连接验证查询
      validate: async (client) => {
        await client.query('SELECT 1');
        return true;
      }
    };

    this.pool = new Pool(this.config);
  }

  // 获取连接
  async getConnection(): Promise<any> {
    return this.pool.connect();
  }

  // 执行查询
  async query(text: string, params?: any[]): Promise<any> {
    const client = await this.getConnection();
    try {
      const result = await client.query(text, params);
      return result;
    } finally {
      client.release();
    }
  }

  // 事务执行
  async transaction<T>(callback: (client: any) => Promise<T>): Promise<T> {
    const client = await this.getConnection();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  // 获取连接池统计
  getPoolStats(): PoolStats {
    return {
      totalCount: this.pool.totalCount,
      idleCount: this.pool.idleCount,
      waitingCount: this.pool.waitingCount
    };
  }

  // 关闭连接池
  async close(): Promise<void> {
    await this.pool.end();
  }
}

interface PoolStats {
  totalCount: number;
  idleCount: number;
  waitingCount: number;
}

export default DatabaseConnectionPool;
```

#### 查询优化
```typescript
// src/repositories/CharacterRepository.ts
import { DatabaseConnectionPool } from '../database/ConnectionPool';

class CharacterRepository {
  constructor(private db: DatabaseConnectionPool) {}

  // 分页查询优化
  async findCharactersPaginated(
    page: number,
    limit: number,
    filters: CharacterFilters = {}
  ): Promise<PaginatedResult<Character>> {
    const offset = (page - 1) * limit;

    // 构建查询条件
    const whereConditions = [];
    const queryParams: any[] = [];

    if (filters.position) {
      whereConditions.push('position = $' + (whereConditions.length + 1));
      queryParams.push(filters.position);
    }

    if (filters.isActive !== undefined) {
      whereConditions.push('is_active = $' + (whereConditions.length + 1));
      queryParams.push(filters.isActive);
    }

    const whereClause = whereConditions.length > 0 ? 'WHERE ' + whereConditions.join(' AND ') : '';

    // 使用索引优化的查询
    const query = `
      SELECT
        id, name, display_name, position, personality,
        created_at, updated_at, is_active
      FROM characters
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}
    `;

    queryParams.push(limit, offset);

    const countQuery = `
      SELECT COUNT(*) as total
      FROM characters
      ${whereClause}
    `;

    const [results, countResult] = await Promise.all([
      this.db.query(query, queryParams),
      this.db.query(countQuery, queryParams.slice(0, -2))
    ]);

    return {
      items: results.rows,
      total: parseInt(countResult.rows[0].total),
      page,
      limit,
      totalPages: Math.ceil(countResult.rows[0].total / limit)
    };
  }

  // 批量插入优化
  async createMany(characters: CharacterData[]): Promise<Character[]> {
    if (characters.length === 0) {
      return [];
    }

    // 使用 COPY 命令进行批量插入
    const columns = ['name', 'display_name', 'position', 'personality', 'user_id', 'created_at', 'updated_at'];
    const values = characters.map(char => [
      char.name,
      char.displayName,
      char.position,
      char.personality,
      char.userId,
      new Date(),
      new Date()
    ]);

    const query = `
      INSERT INTO characters (${columns.join(', ')})
      VALUES ${values.map((_, index) =>
        '$' + Array(columns.length).fill(0).map((_, i) => index * columns.length + i + 1).join(', ')
      ).join('), ')}, ${values.map((_, index) =>
        '$' + Array(columns.length).fill(0).map((_, i) => index * columns.length + i + 1).join(', ')
      ).join(', ')})})
      RETURNING *
    `;

    const flatParams = values.flat();
    const result = await this.db.query(query, flatParams);

    return result.rows;
  }

  // 使用 CTE 的复杂查询优化
  async findCharactersWithRecentMemories(
    characterIds: string[],
    memoryLimit: number = 5
  ): Promise<CharacterWithMemories[]> {
    const query = `
      WITH character_data AS (
        SELECT id, name, display_name, position, personality
        FROM characters
        WHERE id = ANY($1)
      ),
      recent_memories AS (
        SELECT DISTINCT ON (character_id)
          character_id, content, importance, created_at
        FROM memories
        WHERE character_id = ANY($1)
        ORDER BY character_id, importance DESC, created_at DESC
      )
      SELECT
        cd.*,
        json_agg(
          json_build_object(
            'content', rm.content,
            'importance', rm.importance,
            'created_at', rm.created_at
          )
        ) ORDER BY rm.importance DESC, rm.created_at DESC
        ) as memories
      FROM character_data cd
      LEFT JOIN recent_memories rm ON cd.id = rm.character_id
      GROUP BY cd.id, cd.name, cd.display_name, cd.position, cd.personality
    `;

    const result = await this.db.query(query, [characterIds]);
    return result.rows;
  }

  // 索引使用查询
  async findByComplexFilters(filters: ComplexCharacterFilters): Promise<Character[]> {
    const whereConditions: string[] = [];
    const queryParams: any[] = [];

    // 使用索引的查询条件
    if (filters.positionRange) {
      whereConditions.push(`position BETWEEN $${whereConditions.length + 1} AND $${whereConditions.length + 2}`);
      queryParams.push(filters.positionRange.min, filters.positionRange.max);
    }

    if (filters.createdAtRange) {
      whereConditions.push(`created_at BETWEEN $${whereConditions.length + 1} AND $${whereConditions.length + 2}`);
      queryParams.push(filters.createdAtRange.start, filters.createdAtRange.end);
    }

    if (filters.minImportance !== undefined) {
      whereConditions.push(`
        id IN (
          SELECT DISTINCT character_id
          FROM memories
          WHERE importance >= $${whereConditions.length + 1}
        )
      `);
      queryParams.push(filters.minImportance);
    }

    const whereClause = whereConditions.length > 0 ? 'WHERE ' + whereConditions.join(' AND ') : '';

    const query = `
      SELECT id, name, display_name, position, personality, created_at, updated_at, is_active
      FROM characters
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT 100
    `;

    const result = await this.db.query(query, queryParams);
    return result.rows;
  }
}

// 类型定义
interface Character {
  id: string;
  name: string;
  displayName: string;
  position: string;
  personality: string;
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
}

interface CharacterData {
  name: string;
  displayName: string;
  position: string;
  personality: string;
  userId: string;
}

interface CharacterFilters {
  position?: string;
  isActive?: boolean;
  createdAfter?: Date;
  createdBefore?: Date;
}

interface ComplexCharacterFilters {
  positionRange?: { min: string; max: string };
  createdAtRange?: { start: Date; end: Date };
  minImportance?: number;
}

interface CharacterWithMemories extends Character {
  memories: Array<{
    content: string;
    importance: number;
    createdAt: Date;
  }>;
}

interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export default CharacterRepository;
```

### 2. 缓存层优化

#### Redis 缓存实现
```typescript
// src/cache/RedisCache.ts
import Redis from 'ioredis';

interface CacheOptions {
  ttl?: number;
  tags?: string[];
  compress?: boolean;
}

class RedisCache {
  private client: Redis;

  constructor(redisConfig: Redis.RedisOptions) {
    this.client = new Redis(redisConfig);

    // 设置键的前缀
    this.client.defineCommand('cacheGet', (numberofArgs) => {
      return {
        keys: numberOfArgs,
        transform: (args: string[]) => {
          return ['GET', `cache:${args[0]}`];
        }
      };
    });

    this.client.defineCommand('cacheSet', (numberOfArgs) => {
      return {
        keys: numberOfArgs,
        transform: (args: any[]) => {
          const [key, value, options] = args;
          const redisArgs = ['SET', `cache:${key}`, JSON.stringify(value)];

          if (options?.ttl) {
            redisArgs.push('EX', options.ttl.toString());
          }

          if (options?.tags) {
            redisArgs.push('TAG', ...options.tags);
          }

          return redisArgs;
        }
      };
    });
  }

  // 设置缓存
  async set<T>(key: string, data: T, options?: CacheOptions): Promise<void> {
    const serializedData = options?.compress
      ? await this.compress(JSON.stringify(data))
      : JSON.stringify(data);

    await this.client.cacheSet(key, serializedData, options);
  }

  // 获取缓存
  async get<T>(key: string): Promise<T | null> {
    try {
      const data = await this.client.cacheGet(key);

      if (!data) {
        return null;
      }

      // 检查是否压缩过
      const isCompressed = data.startsWith('COMPRESSED:');
      const jsonData = isCompressed
        ? await this.decompress(data.substring(10))
        : data;

      return JSON.parse(jsonData);
    } catch (error) {
      console.error(`Cache get error for key ${key}:`, error);
      return null;
    }
  }

  // 删除缓存
  async delete(key: string): Promise<boolean> {
    try {
      const result = await this.client.del(`cache:${key}`);
      return result > 0;
    } catch (error) {
      console.error(`Cache delete error for key ${key}:`, error);
      return false;
    }
  }

  // 批量删除
  async deleteMultiple(keys: string[]): Promise<number> {
    const redisKeys = keys.map(key => `cache:${key}`);
    return await this.client.del(redisKeys);
  }

  // 按标签删除
  async deleteByTag(tag: string): Promise<number> {
    return await this.client.delByTag(tag);
  }

  // 获取缓存统计
  async getStats(): Promise<CacheStats> {
    const info = await this.client.info('memory');
    const keyspace = info.split('\r\n');

    const usedMemory = this.parseMemoryInfo(keyspace.find(line => line.includes('used_memory:')));
    const keysCount = this.parseMemoryInfo(keyspace.find(line => line.includes('db')))?.split(',')[1] || '0');

    return {
      usedMemory,
      totalKeys: parseInt(keysCount),
      hitRate: await this.calculateHitRate(),
      memoryUsagePercent: this.calculateMemoryUsagePercent(usedMemory)
    };
  }

  // 缓存预热
  async warmup(preloadData: PreloadData[]): Promise<void> {
    const promises = preloadData.map(async (data) => {
      await this.set(data.key, data.value, {
        ttl: data.ttl,
        tags: data.tags
      });
    });

    await Promise.all(promises);
  }

  // 数据压缩
  private async compress(data: string): Promise<string> {
    // 使用 zlib 压缩
    const zlib = require('zlib');
    const compressed = zlib.deflateSync(Buffer.from(data));
    return 'COMPRESSED:' + compressed.toString('base64');
  }

  // 数据解压
  private async decompress(compressedData: string): Promise<string> {
    const zlib = require('zlib');
    const buffer = Buffer.from(compressedData, 'base64');
    const decompressed = zlib.inflateSync(buffer);
    return decompressed.toString();
  }

  private parseMemoryInfo(line?: string): number {
    if (!line) return 0;
    const match = line.match(/:(\d+)/);
    return match ? parseInt(match[1]) : 0;
  }

  private async calculateHitRate(): Promise<number> {
    try {
      const stats = await this.client.info('stats');
      const keyspace = stats.split('\r\n');

      const hitsLine = keyspace.find(line => line.includes('keyspace_hits:'));
      const missesLine = keyspace.find(line => line.includes('keyspace_misses:'));

      const hits = this.parseMemoryInfo(hitsLine);
      const misses = this.parseMemoryInfo(missesLine);

      return hits + misses > 0 ? hits / (hits + misses) : 0;
    } catch {
      return 0;
    }
  }

  private calculateMemoryUsagePercent(usedMemory: number): number {
    // 假设 Redis 最大内存为 2GB
    const maxMemory = 2 * 1024 * 1024 * 1024;
    return (usedMemory / maxMemory) * 100;
  }

  // 关闭连接
  async close(): Promise<void> {
    await this.client.quit();
  }
}

interface CacheStats {
  usedMemory: number;
  totalKeys: number;
  hitRate: number;
  memoryUsagePercent: number;
}

interface PreloadData {
  key: string;
  value: any;
  ttl?: number;
  tags?: string[];
}

export default RedisCache;
```

### 3. AI 服务性能优化

#### 批处理优化
```typescript
// src/services/AIOptimizer.ts
class AIOptimizer {
  private batchSize: number = 10;
  private queue: Map<string, AIOperation[]> = new Map();
  private processing = new Set<string>();

  constructor(private aiService: AIService) {}

  // 批量处理 AI 请求
  async processBatch(operations: AIOperation[]): Promise<AIOperationResult[]> {
    const startTime = Date.now();

    try {
      // 按模型类型分组
      const groupedOperations = this.groupOperationsByModel(operations);

      const results: AIOperationResult[] = [];

      for (const [modelType, ops] of groupedOperations) {
        const batchResults = await this.processBatchForModel(modelType, ops);
        results.push(...batchResults);
      }

      const processingTime = Date.now() - startTime;
      console.log(`Processed ${operations.length} operations in ${processingTime}ms`);

      return results;
    } catch (error) {
      console.error('Batch processing failed:', error);
      throw error;
    }
  }

  // 智能批处理 - 自动合并相似请求
  async processSmart(operation: AIOperation): Promise<AIOperationResult> {
    const batchKey = this.getBatchKey(operation);

    // 如果该模型正在处理，加入队列
    if (this.processing.has(batchKey)) {
      if (!this.queue.has(batchKey)) {
        this.queue.set(batchKey, []);
      }
      this.queue.get(batchKey)!.push(operation);

      // 等待当前批次处理完成
      await this.waitForBatchCompletion(batchKey);
    } else {
      // 开始新批次
      this.processing.add(batchKey);

      // 等待更多请求加入批次
      await this.waitForBatchAccumulation(batchKey);

      const batchOperations = this.queue.get(batchKey) || [];
      batchOperations.push(operation);
      this.queue.delete(batchKey);

      // 处理批次
      const results = await this.processBatch(batchOperations);

      this.processing.delete(batchKey);

      // 返回当前操作的结果
      return results.find(r => r.operationId === operation.id)!;
    }

    return this.processSingle(operation);
  }

  private groupOperationsByModel(operations: AIOperation[]): Map<string, AIOperation[]> {
    const groups = new Map<string, AIOperation[]>();

    for (const operation of operations) {
      const modelType = this.getModelType(operation);
      if (!groups.has(modelType)) {
        groups.set(modelType, []);
      }
      groups.get(modelType)!.push(operation);
    }

    return groups;
  }

  private async processBatchForModel(
    modelType: string,
    operations: AIOperation[]
  ): Promise<AIOperationResult[]> {
    // 根据模型类型选择优化策略
    switch (modelType) {
      case 'text-generation':
        return this.processTextGenerationBatch(operations);
      case 'conversation':
        return this.processConversationBatch(operations);
      case 'decision-making':
        return this.processDecisionBatch(operations);
      default:
        return this.processGenericBatch(operations);
    }
  }

  private async processTextGenerationBatch(
    operations: AIOperation[]
  ): Promise<AIOperationResult[]> {
    // 文本生成可以并行处理
    const promises = operations.map(op => this.processSingle(op));
    return Promise.all(promises);
  }

  private async processConversationBatch(
    operations: AIOperation[]
  ): Promise<AIOperationResult[]> {
    // 对话请求需要保持上下文顺序
    const results: AIOOperationResult[] = [];

    for (const operation of operations) {
      const result = await this.processSingle(operation);
      results.push(result);
    }

    return results;
  }

  private async processDecisionBatch(
    operations: AIOperation[]
  ): Promise<AIOperationResult[]> {
    // 决策请求可以并行处理
    const promises = operations.map(op => this.processSingle(op));
    return Promise.all(promises);
  }

  private async processGenericBatch(
    operations: AIOperation[]
  ): Promise<AIOperationResult[]> {
    // 通用批处理策略
    const batchSize = Math.min(operations.length, this.batchSize);
    const batches: AIOperation[][] = [];

    for (let i = 0; i < operations.length; i += batchSize) {
      batches.push(operations.slice(i, i + batchSize));
    }

    const results: AIOperationResult[] = [];
    for (const batch of batches) {
      const batchResults = await Promise.all(
        batch.map(op => this.processSingle(op))
      );
      results.push(...batchResults);
    }

    return results;
  }

  private getBatchKey(operation: AIOperation): string {
    return `${operation.model}:${operation.type}:${operation.priority || 'normal'}`;
  }

  private getModelType(operation: AIOperation): string {
    return operation.model || 'default';
  }

  private async waitForBatchAccumulation(batchKey: string): Promise<void> {
    return new Promise(resolve => {
      setTimeout(() => {
        resolve(undefined);
      }, 100); // 100ms 批次累积时间
    });
  }

  private async waitForBatchCompletion(batchKey: string): Promise<void> {
    while (this.processing.has(batchKey)) {
      await new Promise(resolve => setTimeout(resolve, 10));
    }
  }

  private async processSingle(operation: AIOperation): Promise<AIOperationResult> {
    const startTime = Date.now();

    try {
      const result = await this.aiService.executeOperation(operation);

      return {
        operationId: operation.id,
        result,
        success: true,
        processingTime: Date.now() - startTime,
        modelUsed: operation.model
      };
    } catch (error) {
      return {
        operationId: operation.id,
        result: null,
        success: false,
        error: error.message,
        processingTime: Date.now() - startTime,
        modelUsed: operation.model
      };
    }
  }

  // 获取性能统计
  getPerformanceStats(): AIOptimizerStats {
    const queueSizes = Array.from(this.queue.entries()).map(([key, queue]) => ({
      key,
      size: queue.length
    }));

    return {
      queueSizes,
      processingCount: this.processing.size,
      batchSize: this.batchSize,
      totalProcessed: this.totalProcessed,
      averageProcessingTime: this.averageProcessingTime
    };
  }

  private totalProcessed = 0;
  private averageProcessingTime = 0;
}

interface AIOperation {
  id: string;
  type: string;
  model?: string;
  priority?: 'low' | 'normal' | 'high';
  prompt: string;
  context?: any;
}

interface AIOperationResult {
  operationId: string;
  result: any;
  success: boolean;
  error?: string;
  processingTime: number;
  modelUsed?: string;
}

interface AIOptimizerStats {
  queueSizes: Array<{ key: string; size: number }>;
  processingCount: number;
  batchSize: number;
  totalProcessed: number;
  averageProcessingTime: number;
}

export default AIOptimizer;
```

## 📊 监控系统实现

### 1. 应用性能监控 (APM)

#### 自定义 APM 实现
```typescript
// src/monitoring/APM.ts
import EventEmitter from 'events';

interface PerformanceMetric {
  name: string;
  value: number;
  timestamp: number;
  tags: Record<string, string>;
}

interface TraceData {
  traceId: string;
  spanId: string;
  parentSpanId?: string;
  operationName: string;
  startTime: number;
  endTime?: number;
  duration?: number;
  tags: Record<string, string>;
  status: 'pending' | 'completed' | 'error';
  error?: Error;
}

class APMService extends EventEmitter {
  private traces = new Map<string, TraceData>();
  private metrics: PerformanceMetric[] = [];
  private activeSpans = new Map<string, TraceData>();

  constructor() {
    super();

    // 定期清理过期数据
    setInterval(() => this.cleanup(), 60000); // 每分钟清理一次

    // 定期上报指标
    setInterval(() => this.reportMetrics(), 30000); // 每30秒上报一次
  }

  // 开始跟踪
  startTrace(operationName: string, tags: Record<string, string> = {}): string {
    const traceId = this.generateTraceId();
    const spanId = this.generateSpanId();

    const trace: TraceData = {
      traceId,
      spanId,
      operationName,
      startTime: Date.now(),
      tags,
      status: 'pending'
    };

    this.traces.set(traceId, trace);
    this.activeSpans.set(spanId, trace);

    this.emit('trace:started', trace);

    return traceId;
  }

  // 完成跟踪
  endTrace(traceId: string, error?: Error): void {
    const trace = this.traces.get(traceId);
    if (!trace) return;

    trace.endTime = Date.now();
    trace.duration = trace.endTime - trace.startTime;
    trace.status = error ? 'error' : 'completed';
    if (error) {
      trace.error = error;
    }

    this.activeSpans.delete(trace.spanId);
    this.traces.set(traceId, trace);

    this.emit('trace:completed', trace);

    // 记录指标
    this.recordMetric('trace.duration', trace.duration, {
      operation: trace.operationName,
      status: trace.status
    });
  }

  // 记录指标
  recordMetric(name: string, value: number, tags: Record<string, string> = {}): void {
    const metric: PerformanceMetric = {
      name,
      value,
      timestamp: Date.now(),
      tags
    };

    this.metrics.push(metric);

    // 保持指标数组大小合理
    if (this.metrics.length > 10000) {
      this.metrics = this.metrics.slice(-5000); // 保留最近5000个指标
    }

    this.emit('metric:recorded', metric);
  }

  // 记录 HTTP 请求
  recordHttpRequest(req: any, res: any, duration: number): void {
    this.recordMetric('http.request.duration', duration, {
      method: req.method,
      route: req.route?.path || req.path,
      statusCode: res.statusCode.toString()
    });

    if (res.statusCode >= 400) {
      this.recordMetric('http.request.error', 1, {
        method: req.method,
        route: req.route?.path || req.path,
        statusCode: res.statusCode.toString()
      });
    }
  }

  // 记录数据库查询
  recordDatabaseQuery(query: string, duration: number, error?: Error): void {
    const queryType = this.getQueryType(query);

    this.recordMetric('database.query.duration', duration, {
      queryType,
      hasError: !!error
    });

    if (error) {
      this.recordMetric('database.query.error', 1, {
        queryType,
        errorType: error.constructor.name
      });
    }
  }

  // 记录 AI 模型调用
  recordAICall(model: string, operation: string, duration: number, success: boolean): void {
    this.recordMetric('ai.call.duration', duration, {
      model,
      operation,
      success
    });

    if (!success) {
      this.recordMetric('ai.call.error', 1, {
        model,
        operation
      });
    }
  }

  // 获取性能统计
  getPerformanceStats(): PerformanceStats {
    const now = Date.now();
    const oneHourAgo = now - 3600000;

    // 计算最近一小时的指标
    const recentMetrics = this.metrics.filter(m => m.timestamp > oneHourAgo);
    const recentTraces = Array.from(this.traces.values()).filter(t => t.startTime > oneHourAgo);

    const traceStats = this.calculateTraceStats(recentTraces);
    const metricStats = this.calculateMetricStats(recentMetrics);

    return {
      timestamp: now,
      traces: traceStats,
      metrics: metricStats,
      activeTraces: this.activeSpans.size,
      queueSize: this.getQueueSize()
    };
  }

  // 创建分布式跟踪头
  createDistributedHeaders(traceId: string): Record<string, string> {
    return {
      'x-trace-id': traceId,
      'x-b3-traceid': traceId,
      'x-b3-spanid': this.generateSpanId()
    };
  }

  // 清理过期数据
  private cleanup(): void {
    const oneHourAgo = Date.now() - 3600000;

    // 清理过期跟踪
    for (const [traceId, trace] of this.traces.entries()) {
      if (trace.startTime < oneHourAgo) {
        this.traces.delete(traceId);
      }
    }

    // 清理过期指标
    this.metrics = this.metrics.filter(m => m.timestamp > oneHourAgo);
  }

  // 上报指标到监控系统
  private async reportMetrics(): Promise<void> {
    const stats = this.getPerformanceStats();

    try {
      // 上报到 Prometheus/Prometheus
      await this.reportToPrometheus(stats);

      // 上报到 Grafana
      await this.reportToGrafana(stats);

      // 上报到自定义监控平台
      await this.reportToCustomSystem(stats);
    } catch (error) {
      console.error('Failed to report metrics:', error);
    }
  }

  private async reportToPrometheus(stats: PerformanceStats): Promise<void> {
    // Prometheus 指标格式
    const prometheusMetrics = [
      `# HELP ai_performance_metrics AI Performance Metrics`,
      `# TYPE ai_performance_metrics gauge`,
      `ai_performance_total_traces ${stats.traces.total}`,
      `ai_performance_active_traces ${stats.activeTraces}`,
      `ai_performance_queue_size ${stats.queueSize}`,
      `ai_performance_error_rate ${stats.metrics.errorRate}`,
      `ai_performance_average_response_time ${stats.metrics.averageResponseTime}`
    ];

    // 发送到 Prometheus Pushgateway
    // await this.pushToPrometheus(prometheusMetrics.join('\n'));
  }

  private async reportToGrafana(stats: PerformanceStats): Promise<void> {
    // 格式化为 Grafana 可用的数据
    const grafanaData = {
      timestamp: stats.timestamp,
      traces: stats.traces,
      metrics: stats.metrics
    };

    // 发送到 Grafana API
    // await fetch('https://your-grafana.com/api/datasources', {
    //   method: 'POST',
    //   headers: { 'Authorization': 'Bearer ' + process.env.GRAFANA_TOKEN },
    //   body: JSON.stringify(grafanaData)
    // });
  }

  private async reportToCustomSystem(stats: PerformanceStats): Promise<void> {
    // 发送到自定义监控 API
    // await fetch('https://your-monitoring-api.com/metrics', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify(stats)
    // });
  }

  private calculateTraceStats(traces: TraceData[]): TraceStats {
    const totalTraces = traces.length;
    const completedTraces = traces.filter(t => t.status === 'completed');
    const errorTraces = traces.filter(t => t.status === 'error');
    const averageDuration = completedTraces.length > 0
      ? completedTraces.reduce((sum, t) => sum + (t.duration || 0), 0) / completedTraces.length
      : 0;

    return {
      total: totalTraces,
      completed: completedTraces.length,
      errors: errorTraces.length,
      averageDuration: Math.round(averageDuration),
      p95Duration: this.calculatePercentile(traces.map(t => t.duration || 0), 0.95),
      p99Duration: this.calculatePercentile(traces.map(t => t.duration || 0), 0.99)
    };
  }

  private calculateMetricStats(metrics: PerformanceMetric[]): MetricStats {
    const errorMetrics = metrics.filter(m => m.name.includes('error'));
    const durationMetrics = metrics.filter(m => m.name.includes('duration'));

    return {
      total: metrics.length,
      errors: errorMetrics.length,
      errorRate: metrics.length > 0 ? errorMetrics.length / metrics.length : 0,
      averageResponseTime: durationMetrics.length > 0
        ? Math.round(durationMetrics.reduce((sum, m) => sum + m.value, 0) / durationMetrics.length)
        : 0
    };
  }

  private calculatePercentile(values: number[], percentile: number): number {
    const sorted = [...values].sort((a, b) => a - b);
    const index = Math.ceil((percentile / 100) * sorted.length);
    return sorted[Math.max(0, index - 1)];
  }

  private getQueryType(query: string): string {
    const lowerQuery = query.toLowerCase().trim();

    if (lowerQuery.startsWith('select')) return 'select';
    if (lowerQuery.startsWith('insert')) return 'insert';
    if (lowerQuery.startsWith('update')) return 'update';
    if (lowerQuery.startsWith('delete')) return 'delete';
    if (lowerQuery.startsWith('create')) return 'create';
    if (lowerQuery.startsWith('alter')) return 'alter';
    if (lowerQuery.startsWith('drop')) return 'drop';

    return 'other';
  }

  private getQueueSize(): number {
    // 实现获取系统队列大小
    return 0; // 占位符
  }

  private generateTraceId(): string {
    return `trace_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private generateSpanId(): string {
    return `span_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

interface PerformanceStats {
  timestamp: number;
  traces: TraceStats;
  metrics: MetricStats;
  activeTraces: number;
  queueSize: number;
}

interface TraceStats {
  total: number;
  completed: number;
  errors: number;
  averageDuration: number;
  p95Duration: number;
  p99Duration: number;
}

interface MetricStats {
  total: number;
  errors: number;
  errorRate: number;
  averageResponseTime: number;
}

export default APMService;
```

### 2. 基础设施监控

#### Docker 容器监控
```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  # Prometheus 监控
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
    networks:
      - monitoring

  # Grafana 可视化
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
    networks:
      - monitoring

  # Node Exporter
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs/host:ro
    networks:
      - monitoring

  # cAdvisor (容器监控)
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    networks:
      - monitoring

  # 自定义应用监控
  app-monitor:
    build:
      context: .
      dockerfile: Dockerfile.monitor
    container_name: app-monitor
    ports:
      - "8081:8081"
    environment:
      - PROMETHEUS_GATEWAY_URL=http://prometheus:9090
      - METRICS_PATH=/metrics
      - NODE_ENV=production
    depends_on:
      - prometheus
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:
  grafana_config:
  grafana_dashboards:

networks:
  monitoring:
    driver: bridge
```

#### Prometheus 配置
```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - - alertmanager:9093

scrape_configs:
  # 应用监控
  - job_name: 'ai-world-app'
    static_configs:
      - targets: ['app-monitor:8081']
    scrape_interval: 10s
    metrics_path: '/metrics'
    scrape_timeout: 5s

  # Node Exporter
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 15s

  # cAdvisor
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
    scrape_interval: 30s

  # Prometheus 自身监控
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

# 告警规则
rule_files:
  - "alert_rules.yml"
```

#### 告警规则配置
```yaml
# monitoring/alert_rules.yml
groups:
  - name: ai-world-alerts
    rules:
      # 高错误率告警
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }} over the last 5 minutes"

      # AI 服务响应时间告警
      - alert: AIServiceHighLatency
        expr: histogram_quantile(0.95, rate(ai_call_duration_seconds_bucket[5m])) > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "AI service high latency"
          description: "95th percentile response time is {{ $value }}s"

      # 数据库连接池告警
      - alert: DatabaseConnectionPoolExhaustion
        expr: (database_connections_active / database_connections_max) > 0.9
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Database connection pool nearly exhausted"
          description: "Connection pool usage is {{ $value | humanizePercentage }}"

      # 内存使用率告警
      - alert: HighMemoryUsage
        expr: (nodejs_heap_size_used / nodejs_heap_size_total) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value | humanizePercentage }}"

      # 队列积压告警
      - alert: QueueBacklog
        expr: queue_size > 100
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Queue backlog detected"
          description: "Queue size is {{ $value }} items"

      # 磁盘空间告警
      - alert: LowDiskSpace
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space"
          description: "Available disk space is {{ $value | humanizePercentage }}"
```

---

_文档版本: v1.0_
_最后更新: 2024-11-10_
_维护者: AI开发团队_

这份性能优化与监控指南为AI系统提供了全面的性能管理方案，从前端渲染优化到后端数据库优化，从AI模型性能调优到基础设施监控，确保系统在各种负载条件下都能保持良好的性能表现。通过持续的监控和优化，可以及时发现性能瓶颈并进行针对性的改进。