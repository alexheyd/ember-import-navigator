# Ember Import Navigator

Based off `amd-navigator` package: [https://github.com/zboro/amd-navigator](https://github.com/zboro/amd-navigator)

This package is for Ember Apps with `usePods: true` and will open the relevant file for an imported module based on where the cursor is located.

You can open the module by pressing `Ctrl+Alt+E` when your cursor is on the module variable or the import path. This also works with module method names, and for functions declared in the same file, it uses Atom's native `Symbols View` package.

### Example
With the following import line:

```javascript
	import FooMixin from 'my-project/mixins/foo'
```

The package will look for a `package.json` file in the root of the current file to determine the project name. It will replace the project name found in the import path and unless the import path contains `config`, it will look for the file in the `app` directory, assuming a default Ember folder structure:

```
/project-root
	/app
		/mixins
			foo.js
	/config
```

File extension is assumed to be `.js`

The package _could_ check for the existence of the folder first, and then check the project root for the same folder name, but checking if a directory exists returns a promise, which would slow the package down.

### Known issues

Soft wrap and code folding break opening modules when cursor is in string. (atom/atom#8685)
