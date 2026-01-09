(method_declaration
  receiver: (parameter_list
    (parameter_declaration
      name: (identifier) @receiver)))

(method_declaration
  receiver: (parameter_list
    (parameter_declaration
      name: (identifier) @_recv_name))
  body: (block
    (identifier) @receiver.usage
    (#eq? @receiver.usage @_recv_name)))
