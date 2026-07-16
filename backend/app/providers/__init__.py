"""Provider adapters.

Each module in this package implements the unified :class:`~app.providers.base.Provider`
protocol for a specific upstream model-provider protocol. The rest of the
application talks to providers only through the abstract interface, so adding
support for a new protocol is a matter of adding a new module here.
"""
