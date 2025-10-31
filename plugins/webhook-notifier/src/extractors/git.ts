/**
 * Git Information Extractor
 * 提取项目的 Git 元数据
 */
import { execSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";
import type { GitInfo } from "../types/payload.js";

export class GitExtractor {
  /**
   * 从项目目录提取 Git 信息
   */
  extract(projectDir: string): GitInfo {
    // 检查是否是 Git 仓库
    if (!this.isGitRepository(projectDir)) {
      return {
        branch: null,
        repo: null,
        commit: null,
      };
    }

    return {
      branch: this.getBranch(projectDir),
      repo: this.getRemoteUrl(projectDir),
      commit: this.getCommitHash(projectDir),
    };
  }

  /**
   * 检查是否是 Git 仓库
   */
  private isGitRepository(projectDir: string): boolean {
    return existsSync(join(projectDir, ".git"));
  }

  /**
   * 获取当前分支名
   */
  private getBranch(projectDir: string): string | null {
    try {
      const branch = execSync("git rev-parse --abbrev-ref HEAD", {
        cwd: projectDir,
        encoding: "utf-8",
      }).trim();

      return branch || null;
    } catch {
      return null;
    }
  }

  /**
   * 获取远程仓库 URL
   */
  private getRemoteUrl(projectDir: string): string | null {
    try {
      const url = execSync("git config --get remote.origin.url", {
        cwd: projectDir,
        encoding: "utf-8",
      }).trim();

      return url || null;
    } catch {
      return null;
    }
  }

  /**
   * 获取当前 commit hash（短版本）
   */
  private getCommitHash(projectDir: string): string | null {
    try {
      const hash = execSync("git rev-parse --short HEAD", {
        cwd: projectDir,
        encoding: "utf-8",
      }).trim();

      return hash || null;
    } catch {
      return null;
    }
  }
}
