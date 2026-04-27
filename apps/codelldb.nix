{
  writeShellScriptBin,
  vscode-extensions,
}:
# Extract codelldb from the vscode-lldb extension.
writeShellScriptBin "codelldb" ''
  exec -a $0 ${vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb $@
''
