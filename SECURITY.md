# Security and privacy

This unofficial add-on opens a loopback-only debugging endpoint at `127.0.0.1:39222` to render quota in the desktop UI. This interface can execute renderer code and is not authenticated against other local processes. Do not forward it, expose it, or change the bind address to a network interface.

The helper reads quota using the local Codex CLI app-server (`account/rateLimits/read`). It does not need a separate API key, and the add-on does not export login tokens or read the conversation database. This statement covers the add-on code, not the data handling of the official desktop client or CLI.

Installation creates a per-user logon task and copies a user-selected Node runtime into the tool directory. The startup supervisor can perform one guarded relaunch of a newly started, still invisible supported app. It skips existing/visible sessions and occupied ports. It does not modify the signed desktop application files, firewall, antivirus or proxy settings.

The integration relies on internal desktop and CLI interfaces. An application update may break compatibility even though it does not remove the independently stored installation. No permanent compatibility or account-availability guarantee is made.

Uninstall stops owned helper processes, removes the task, removes the card when its endpoint is reachable, and deletes only known tool files. Fully exit/reopen the client afterwards to close the debugging endpoint.

Never upload your installed tool directory as a release: it may contain machine paths, logs and installation state. Use `build-release.ps1`, which builds from a fixed allowlist of source files. Do not post credentials or private logs in public issues. Use GitHub's private vulnerability reporting if it is available for the repository; otherwise contact the maintainer before disclosing sensitive details.
