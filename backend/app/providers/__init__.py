"""Provider adapter。

此包中的每个 module 都为一种特定的上游 model-provider protocol 实现统一的
:class:`~app.providers.base.Provider` protocol。应用的其他部分只通过 abstract interface
与 provider 通信，因此支持新 protocol 只需在这里添加新 module。
"""
