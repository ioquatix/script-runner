ScriptRunner = require '../lib/script-runner'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "ScriptRunner", ->
  activationPromise = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getVew(atom.workspace)
    activationPromise = atom.packages.activatePackage('script-runner')

  describe "when the script-runner:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(workspaceElement.find('.script-runner')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement 'script-runner:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.find('.script-runner')).toExist()
        atom.commands.dispatch workspaceElement 'script-runner:toggle'
        expect(workspaceElement.find('.script-runner')).not.toExist()
