# sapf.nvim

A Neovim plugin for the [sapf](https://github.com/lfnoise/sapf) language and interpreter

![showcase](https://ephemeral.observer/lib/sapf.nvim/showcase.gif)

It's still very WIP. Feel free to contribute.

### Protect your ears and speakers
```
\z[z .995 leakdc 1 clip2 play] = play
```

## Configuration
```lua
local sapf = require 'sapf'
local map = sapf.map

sapf.setup {
	lang = {
		executable = "sapf",
		prelude = '<PATH-TO>/prelude.txt'
	},
	window = {
		size = 0.35,
		wrap = true
	},
	keymaps = {
		['<leader>st'] = map(sapf.start, 'n', {desc ="sapf start"}),
		['<leader>sq'] = map(sapf.quit, 'n', {desc ="sapf quit"}),
		['<C-e>'] = {
			map('editor.send_block', {'i', 'n'}, {desc ="sapf evaluate block/line"}),
			map('editor.send_selection', 'x', {desc ="sapf evaluate selection"}),
		},
		['<M-e>'] = map('editor.send_line', {'n', 'x', 'i'}, {desc = "sapf evaluate line"}),
		['<C-s>'] = map('lang.stop', {'n', 'i'}, {desc ="sapf stop"}),
		['<C-k>'] = map('help.word', {'n', 'i'}, {desc ="show help for word under cursor"}),
		['<M-h>'] = map('help.all', 'n', {desc ="list help for all built-ins"}),
		['<leader>cc'] = map('lang.clear', {'n', 'i'}, {desc = "sapf clear"}),
		['<leader>cd'] = map('lang.cleard', {'n', 'i'}, {desc = "sapf cleard"}),
	},
	documentation = {
		bif_examples = '<PATH-TO>/sapf-bif-examples.txt',
		examples = '<PATH-TO>/sapf-examples.txt',
	},
}

```

### What block delimiter to use?
```
(
; this is a block
)

```
### Thanks
This plugin is heavily based on [scnvim](https://github.com/davidgranstrom/scnvim) by David Granström.
