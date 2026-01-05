## 0.0.1

* TODO: Describe initial release.

## 0.0.2
- **FIX**: 修复 ContentProvider authority 冲突问题
  - 使用 `${applicationId}` 确保每个应用的 provider 唯一
  - 现在可以与其他使用本 SDK 的应用共存
  - **Breaking Change**: 升级到此版本后，旧的数据库路径会变化（如有）
- 增加 onlyGprinter 字段，用来只搜索佳博打印机