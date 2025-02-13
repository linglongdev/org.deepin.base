# org.deepin.base

这是玲珑的 base 镜像，包含用于运行容器的基础环境。

## 怎么构建

然后执行`./build_base.sh amd64`构建一个 amd64 架构的base。

玲珑使用四位版本号规范，前三位和 [语义化版本 2.0.0](https://semver.org/lang/zh-CN/) 保持一致，第四位用于上游应用无变动，因其他问题需要重新打包时使用。
