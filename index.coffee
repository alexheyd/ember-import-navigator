{CompositeDisposable} = require("atom")
path = require("path")
TagGenerator = require("symbols-view/lib/tag-generator")

FULL_MID_PATTERN = "^(\\w+(?:/\\w+)+)(?:.*?)?$"
RELATIVE_MID_PATTERN = "^((?:..?/)+(?:\\w+/)*\\w+)(?:.*?)?$"
PROJECT_NAME = ""
CURRENT_PROJECT = ""

getTargetFromString = ->
	editor = atom.workspace.getActiveTextEditor()
	# using screen position and bufferRangeForScopeAtPosition is a workaround for https://github.com/atom/atom/issues/8685
	cursorPosition = editor.getCursorScreenPosition()
	midRange = editor.displayBuffer.bufferRangeForScopeAtPosition(".string", cursorPosition)
	return unless midRange
	mid = editor.getTextInBufferRange(editor.bufferRangeForScreenRange(midRange))

	return {
		mid: mid.substring(1, mid.length - 1) #strip quotes
	}

getModuleMap = (moduleName) ->
	editor = atom.workspace.getActiveTextEditor()
	editorText = editor.getText()
	IMPORT_PATTERN = "(?:import (" + moduleName + ") from '(.*?)')"

	match = editorText.match(IMPORT_PATTERN)

	return unless match

	moduleMap = {}

	moduleMap[match[1]] = match[2]

	return moduleMap

getTargetFromVariable = ->
	editor = atom.workspace.getActiveTextEditor()
	cursor = editor.getLastCursor()
	currentWord = editor.getWordUnderCursor().replace(/,/g)
	currentWordRange = cursor.getCurrentWordBufferRange()

	# if current word is preceded with '.', current word is not module, try the previous one
	if editor.getTextInBufferRange([[currentWordRange.start.row, currentWordRange.start.column - 1], currentWordRange.start]) == "."
		# create new temporary cursor, this will place it after '.'
		tempCursor = editor.addCursorAtBufferPosition(cursor.getPreviousWordBoundaryBufferPosition())
		tempCursor.moveToPreviousWordBoundary() # this will move it before '.'
		moduleName = tempCursor.getCurrentWordPrefix().trim()
		functionName = currentWord
		tempCursor.destroy()
	else
		moduleName = currentWord
	moduleMap = getModuleMap(moduleName)
	mid = moduleMap?[moduleName]

	return {
		mid: mid
		functionName: if mid then functionName else currentWord #if we found no mid, maybe currentWord is function in current file
	}

isFullMid = (mid) ->
	mid.match FULL_MID_PATTERN

isRelativeMid = (mid) ->
	mid.match RELATIVE_MID_PATTERN

overrideProjectName = (target) ->
	parts = target.mid.split("/")

	isConfigPath = parts[1] is 'config' and parts[0] is PROJECT_NAME

	if isConfigPath
		parts.shift()
	else
		parts[0] = 'app'

	return parts

openTargetWithFullMid = (target) ->
	# packages = atom.config.get("amd-navigator.packages")
	if !PROJECT_NAME
		console.error "Project name not found."
		return

	midParts = overrideProjectName(target)

	fileName = midParts.pop()

	fileName += ".js" unless fileName.endsWith(".js")

	midParts.push(fileName)

	# fileLocation = path.join(path.join.apply(path, midParts), fileName)
	fileLocation = midParts.join('/')

	return atom.workspace.open(fileLocation)

getAbsoluteFileRoot = ->
	editor = atom.workspace.getActiveTextEditor()
	return atom.project.relativizePath(editor.getPath())[0]

getRelativeFileRoot = ->
	editor = atom.workspace.getActiveTextEditor()
	fileRoot = atom.project.relativizePath(editor.getPath())[1]
	return fileRoot.substring(0, fileRoot.lastIndexOf('/'))

openTargetWithRelativeMid = (target) ->
	# editor = atom.workspace.getActiveTextEditor()
	mid = target.mid
	mid += ".js" unless mid.endsWith(".js")
	# return atom.workspace.open(path.join(path.dirname(editor.getPath()), mid))
	filePath = [getRelativeFileRoot(), mid].join('/')
	return atom.workspace.open(filePath)

goToModule = ->
	currentFileRoot = getAbsoluteFileRoot()

	if CURRENT_PROJECT is currentFileRoot
		openModule()
	else
		atom.project.getDirectories().forEach (directory) ->
			if directory.path is currentFileRoot
				CURRENT_PROJECT = directory.path

				directory.getFile('package.json').read().then((contents) ->
					json = JSON.parse(contents)
					PROJECT_NAME = json.name
					openModule()
				)


openModule = ->
	# "dojo/DeferredList"
	target = getTargetFromString()
	unless target?.mid
		target = getTargetFromVariable()

	if (target.mid)
		openedEditor = openEditor(target)

		if openedEditor
			openedEditor.then((editor) ->
				if target.functionName
					goToFunction(editor, target.functionName)
			)
	else
		goToFunction(atom.workspace.getActiveTextEditor(), target.functionName)

openEditor = (target) ->
	if isFullMid(target.mid)
		return openTargetWithFullMid(target)
	else if isRelativeMid(target.mid)
		return openTargetWithRelativeMid(target)

goToFunction = (editor, functionName) ->
	getFileTags(editor)
	.then((tags) ->
		matchingTags = tags.filter((tag) -> tag.name == functionName)
		return unless matchingTags.length
		setPosition(editor, matchingTags[0].position)
	)

getFileTags = (editor) ->
	#TODO cache tags? check performance
	return new TagGenerator(editor.getPath(), "source.js").generate();

setPosition = (editor, position) ->
	editor.scrollToBufferPosition(position, center: true)
	editor.setCursorBufferPosition(position)
	editor.moveToFirstCharacterOfLine()

module.exports =

	subscriptions: null

	activate: (state) ->
		@subscriptions = new CompositeDisposable()
		@subscriptions.add(atom.commands.add('atom-text-editor', 'ember-import-navigator:go-to-module': => goToModule()))

	deactivate: ->
		@subscriptions.dispose()
