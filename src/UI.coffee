window.UI = UI = new class
  constructor: ->
    @dragging = null
    @mousePosition = {x: 0, y: 0}
    @autofocus = null

    @selectedFn = _.last(appRoot.fns)

    @selectedChildFn = null
    @hoveredChildFn = null

    @expandedChildFns = {}

    @registerEvents()

  registerEvents: ->
    window.addEventListener("mousemove", @handleWindowMouseMove)
    window.addEventListener("mouseup", @handleWindowMouseUp)


  # ===========================================================================
  # Event Util
  # ===========================================================================

  preventDefault: (e) ->
    e.preventDefault()
    util.selection.set(null)


  # ===========================================================================
  # Dragging and Mouse Position
  # ===========================================================================

  handleWindowMouseMove: (e) =>
    @mousePosition = {x: e.clientX, y: e.clientY}
    @dragging?.onMove?(e)

  handleWindowMouseUp: (e) =>
    @dragging?.onUp?(e)
    @dragging = null
    if @hoverIsActive
      @hoverData = null
      @hoverIsActive = false

  getElementUnderMouse: ->
    draggingOverlayEl = document.querySelector(".draggingOverlay")
    draggingOverlayEl?.style.pointerEvents = "none"

    el = document.elementFromPoint(@mousePosition.x, @mousePosition.y)

    draggingOverlayEl?.style.pointerEvents = ""

    return el

  getViewUnderMouse: ->
    el = @getElementUnderMouse()
    el = el?.closest (el) -> el.dataFor?
    return el?.dataFor


  # ===========================================================================
  # Controller
  # ===========================================================================

  selectFn: (fn) ->
    return unless fn instanceof C.DefinedFn
    @selectedFn = fn
    @selectedChildFn = null

  selectChildFn: (childFn) ->
    @selectedChildFn = childFn

  addChildFn: (fn) ->
    if @selectedChildFn
      if @selectedChildFn.fn instanceof C.CompoundFn and @isChildFnExpanded(@selectedChildFn)
        parent = @selectedChildFn.fn
      else
        parent = @findParentOf(@selectedChildFn)

    parent ?= @selectedFn
    childFn = new C.ChildFn(fn)
    parent.childFns.push(childFn)
    @selectChildFn(childFn)

  findParentOf: (childFnTarget) ->
    recurse = (compoundFn) ->
      if _.contains(compoundFn.childFns, childFnTarget)
        return compoundFn

      for childFn in compoundFn.childFns
        if childFn.fn instanceof C.CompoundFn
          if recurse(childFn.fn)
            return childFn.fn

      return null
    recurse(@selectedFn)

  removeChildFn: (fn, childFnIndex) ->
    [removedChildFn] = fn.childFns.splice(childFnIndex, 1)
    if @selectedChildFn == removedChildFn
      @selectChildFn(null)


  isChildFnExpanded: (childFn) ->
    id = C.id(childFn)
    expanded = @expandedChildFns[id]
    if !expanded?
      if childFn.fn instanceof C.DefinedFn
        return false
      else
        return true
    return expanded

  setChildFnExpanded: (childFn, expanded) ->
    id = C.id(childFn)
    @expandedChildFns[id] = expanded

