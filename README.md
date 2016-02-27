# Ember Import Navigator

Based off `amd-navigator` package: [https://github.com/zboro/amd-navigator](https://github.com/zboro/amd-navigator)

This fork no longer supports `require` AMD modules, and no longer has a package config. The lack of a config removes the flexibility to remap the paths any way you want, but also simplifies things by removing that necessity (I only work with Ember apps currently).

This package is primarily for Ember Apps and will open the relevant file for an imported module based on where the cursor is located or which word is selected.

You can open the module by pressing `Ctrl+Alt+E` when your cursor is on the module variable or the import path. This also works with module method names. For functions declared in the same file, it uses Atom's native `Symbols View` package.

### Example
With the following import line:

```javascript
// with cursor on, or selecting, FooMixin or the path, will open project-root/app/mixins/foo.js
import FooMixin from 'my-project/mixins/foo'

// with cursor on, or selecting, bar, will open project-root/app/mixins/foo.js and jump to the bar() method
FooMixin.bar();
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
