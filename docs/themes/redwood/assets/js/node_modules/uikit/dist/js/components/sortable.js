/*! UIkit 3.6.5 | https://www.getuikit.com | (c) 2014 - 2020 YOOtheme | MIT License */

(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('uikit-util')) :
    typeof define === 'function' && define.amd ? define('uikitsortable', ['uikit-util'], factory) :
    (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.UIkitSortable = factory(global.UIkit.util));
}(this, (function (uikitUtil) { 'use strict';

    function getRows(items) {
        return sortBy(items, 'top', 'bottom');
    }

    function sortBy(items, startProp, endProp) {

        var sorted = [[]];

        for (var i = 0; i < items.length; i++) {

            var el = items[i];

            if (!uikitUtil.isVisible(el)) {
                continue;
            }

            var dim = getOffset(el);

            for (var j = sorted.length - 1; j >= 0; j--) {

                var current = sorted[j];

                if (!current[0]) {
                    current.push(el);
                    break;
                }

                var startDim = (void 0);
                if (current[0].offsetParent === el.offsetParent) {
                    startDim = getOffset(current[0]);
                } else {
                    dim = getOffset(el, true);
                    startDim = getOffset(current[0], true);
                }

                if (dim[startProp] >= startDim[endProp] - 1 && dim[startProp] !== startDim[startProp]) {
                    sorted.push([el]);
                    break;
                }

                if (dim[endProp] - 1 > startDim[startProp] || dim[startProp] === startDim[startProp]) {
                    current.push(el);
                    break;
                }

                if (j === 0) {
                    sorted.unshift([el]);
                    break;
                }

            }

        }

        return sorted;
    }

    function getOffset(element, offset) {
        var assign;

        if ( offset === void 0 ) offset = false;

        var offsetTop = element.offsetTop;
        var offsetLeft = element.offsetLeft;
        var offsetHeight = element.offsetHeight;
        var offsetWidth = element.offsetWidth;

        if (offset) {
            (assign = uikitUtil.offsetPosition(element), offsetTop = assign[0], offsetLeft = assign[1]);
        }

        return {
            top: offsetTop,
            left: offsetLeft,
            bottom: offsetTop + offsetHeight,
            right: offsetLeft + offsetWidth
        };
    }

    var clsLeave = 'uk-transition-leave';
    var clsEnter = 'uk-transition-enter';

    function fade(action, target, duration, stagger) {
        if ( stagger === void 0 ) stagger = 40;


        var index = transitionIndex(target, true);
        var propsIn = {opacity: 1};
        var propsOut = {opacity: 0};

        var wrapIndexFn = function (fn) { return function () { return index === transitionIndex(target) ? fn() : uikitUtil.Promise.reject(); }; };

        var leaveFn = wrapIndexFn(function () {

            uikitUtil.addClass(target, clsLeave);

            return uikitUtil.Promise.all(getTransitionNodes(target).map(function (child, i) { return new uikitUtil.Promise(function (resolve) { return setTimeout(function () { return uikitUtil.Transition.start(child, propsOut, duration / 2, 'ease').then(resolve); }, i * stagger); }
                ); }
            )).then(function () { return uikitUtil.removeClass(target, clsLeave); });

        });

        var enterFn = wrapIndexFn(function () {

            var oldHeight = uikitUtil.height(target);

            uikitUtil.addClass(target, clsEnter);
            action();

            uikitUtil.css(uikitUtil.children(target), {opacity: 0});

            return new uikitUtil.Promise(function (resolve) {
                requestAnimationFrame(function () {

                    var nodes = uikitUtil.children(target);
                    var newHeight = uikitUtil.height(target);

                    uikitUtil.height(target, oldHeight);

                    var transitionNodes = getTransitionNodes(target);
                    uikitUtil.css(nodes, propsOut);

                    var transitions = transitionNodes.map(function (child, i) { return new uikitUtil.Promise(function (resolve) { return setTimeout(function () { return uikitUtil.Transition.start(child, propsIn, duration / 2, 'ease').then(resolve); }, i * stagger); }
                        ); }
                    );

                    if (oldHeight !== newHeight) {
                        transitions.push(uikitUtil.Transition.start(target, {height: newHeight}, duration / 2 + transitionNodes.length * stagger, 'ease'));
                    }

                    uikitUtil.Promise.all(transitions).then(function () {
                        uikitUtil.removeClass(target, clsEnter);
                        if (index === transitionIndex(target)) {
                            uikitUtil.css(target, 'height', '');
                            uikitUtil.css(nodes, {opacity: ''});
                            delete target.dataset.transition;
                        }
                        resolve();
                    });
                });
            });
        });

        return uikitUtil.hasClass(target, clsLeave)
            ? waitTransitionend(target).then(enterFn)
            : uikitUtil.hasClass(target, clsEnter)
                ? waitTransitionend(target).then(leaveFn).then(enterFn)
                : leaveFn().then(enterFn);
    }

    function transitionIndex(target, next) {
        if (next) {
            target.dataset.transition = 1 + transitionIndex(target);
        }

        return uikitUtil.toNumber(target.dataset.transition) || 0;
    }

    function waitTransitionend(target) {
        return uikitUtil.Promise.all(uikitUtil.children(target).filter(uikitUtil.Transition.inProgress).map(function (el) { return new uikitUtil.Promise(function (resolve) { return uikitUtil.once(el, 'transitionend transitioncanceled', resolve); }); }
        ));
    }

    function getTransitionNodes(target) {
        return getRows(uikitUtil.children(target)).reduce(function (nodes, row) { return nodes.concat(uikitUtil.sortBy(row.filter(function (el) { return uikitUtil.isInView(el); }), 'offsetLeft')); }, []);
    }

    var targetClass = 'uk-animation-target';

    function slide (action, target, duration) {

        addStyle();

        var nodes = uikitUtil.children(target);

        // Get current state
        var currentProps = nodes.map(function (el) { return getProps(el, true); });
        var oldHeight = uikitUtil.height(target);

        // Cancel previous animations
        uikitUtil.Transition.cancel(target);
        nodes.forEach(uikitUtil.Transition.cancel);
        uikitUtil.removeClass(target, targetClass);
        reset(target);

        // Adding, sorting, removing nodes
        action();

        // Gind new nodes
        nodes = nodes.concat(uikitUtil.children(target).filter(function (el) { return !uikitUtil.includes(nodes, el); }));

        // Gorce update
        uikitUtil.trigger(uikitUtil.toWindow(target), 'resize');
        uikitUtil.fastdom.flush();

        // Get new state
        var newHeight = uikitUtil.height(target);
        var ref = getTransitionProps(target, nodes, currentProps);
        var propsTo = ref[0];
        var propsFrom = ref[1];

        // Reset to previous state
        uikitUtil.addClass(target, targetClass);
        nodes.forEach(function (el, i) { return propsFrom[i] && uikitUtil.css(el, propsFrom[i]); });
        uikitUtil.css(target, {height: oldHeight, display: 'block'});

        // Start transitions on next frame
        return new uikitUtil.Promise(function (resolve) { return requestAnimationFrame(function () {

                var transitions = nodes.map(function (el, i) { return uikitUtil.Transition.start(el, propsTo[i], duration, 'ease'); }
                    ).concat(uikitUtil.Transition.start(target, {height: newHeight}, duration, 'ease'));

                uikitUtil.Promise.all(transitions).then(function () {
                    nodes.forEach(function (el, i) { return uikitUtil.css(el, 'display', propsTo[i].opacity === 0 ? 'none' : ''); });
                    reset(target);
                }, uikitUtil.noop).then(resolve);

            }); }
        );
    }

    function getProps(el, opacity) {

        var zIndex = uikitUtil.css(el, 'zIndex');

        return uikitUtil.isVisible(el)
            ? uikitUtil.assign({
                display: '',
                opacity: opacity ? uikitUtil.css(el, 'opacity') : '0',
                pointerEvents: 'none',
                position: 'absolute',
                zIndex: zIndex === 'auto' ? uikitUtil.index(el) : zIndex
            }, getPositionWithMargin(el))
            : false;
    }

    function getTransitionProps(target, nodes, currentProps) {

        var propsTo = nodes.map(function (el, i) { return uikitUtil.parent(el) && i in currentProps
                ? currentProps[i]
                ? uikitUtil.isVisible(el)
                    ? getPositionWithMargin(el)
                    : {opacity: 0}
                : {opacity: uikitUtil.isVisible(el) ? 1 : 0}
                : false; });

        var propsFrom = propsTo.map(function (props, i) {

            var from = uikitUtil.parent(nodes[i]) === target && (currentProps[i] || getProps(nodes[i]));

            if (!from) {
                return false;
            }

            if (!props) {
                delete from.opacity;
            } else if (!('opacity' in props)) {
                var opacity = from.opacity;

                if (opacity % 1) {
                    props.opacity = 1;
                } else {
                    delete from.opacity;
                }
            }

            return from;
        });

        return [propsTo, propsFrom];
    }

    function reset(el) {
        uikitUtil.css(el.children, {
            height: '',
            left: '',
            opacity: '',
            pointerEvents: '',
            position: '',
            top: '',
            width: '',
            zIndex: ''
        });
        uikitUtil.removeClass(el, targetClass);
        uikitUtil.css(el, {height: '', display: ''});
    }

    function getPositionWithMargin(el) {
        var ref = uikitUtil.offset(el);
        var height = ref.height;
        var width = ref.width;
        var ref$1 = uikitUtil.position(el);
        var top = ref$1.top;
        var left = ref$1.left;

        return {top: top, left: left, height: height, width: width};
    }

    var style;

    function addStyle() {
        if (style) {
            return;
        }
        style = !!uikitUtil.append(document.head, ("<style> ." + targetClass + " > * {\n            margin-top: 0 !important;\n            transform: none !important;\n        } </style>"));
    }

    var Animate = {

        props: {
            duration: Number,
            animation: String
        },

        data: {
            duration: 150,
            animation: 'slide'
        },

        methods: {

            animate: function(action, target) {
                if ( target === void 0 ) target = this.$el;

                var animationFn = this.animation === 'fade' ? fade : slide;
                return animationFn(action, target, this.duration)
                    .then(function () { return uikitUtil.trigger(uikitUtil.toWindow(target), 'resize'); }, uikitUtil.noop);
            }
        }
    };

    var Class = {

        connected: function() {
            !uikitUtil.hasClass(this.$el, this.$name) && uikitUtil.addClass(this.$el, this.$name);
        }

    };

    var Component = {

        mixins: [Class, Animate],

        props: {
            group: String,
            threshold: Number,
            clsItem: String,
            clsPlaceholder: String,
            clsDrag: String,
            clsDragState: String,
            clsBase: String,
            clsNoDrag: String,
            clsEmpty: String,
            clsCustom: String,
            handle: String
        },

        data: {
            group: false,
            threshold: 5,
            clsItem: 'uk-sortable-item',
            clsPlaceholder: 'uk-sortable-placeholder',
            clsDrag: 'uk-sortable-drag',
            clsDragState: 'uk-drag',
            clsBase: 'uk-sortable',
            clsNoDrag: 'uk-sortable-nodrag',
            clsEmpty: 'uk-sortable-empty',
            clsCustom: '',
            handle: false,
            pos: {}
        },

        created: function() {
            var this$1 = this;

            ['init', 'start', 'move', 'end'].forEach(function (key) {
                var fn = this$1[key];
                this$1[key] = function (e) {
                    uikitUtil.assign(this$1.pos, uikitUtil.getEventPos(e));
                    fn(e);
                };
            });
        },

        events: {

            name: uikitUtil.pointerDown,
            passive: false,
            handler: 'init'

        },

        computed: {

            target: function() {
                return (this.$el.tBodies || [this.$el])[0];
            },

            items: function() {
                return uikitUtil.children(this.target);
            },

            isEmpty: {

                get: function() {
                    return uikitUtil.isEmpty(this.items);
                },

                watch: function(empty) {
                    uikitUtil.toggleClass(this.target, this.clsEmpty, empty);
                },

                immediate: true

            },

            handles: {

                get: function(ref, el) {
                    var handle = ref.handle;

                    return handle ? uikitUtil.$$(handle, el) : this.items;
                },

                watch: function(handles, prev) {
                    uikitUtil.css(prev, {touchAction: '', userSelect: ''});
                    uikitUtil.css(handles, {touchAction: uikitUtil.hasTouch ? 'none' : '', userSelect: 'none'}); // touchAction set to 'none' causes a performance drop in Chrome 80
                },

                immediate: true

            }

        },

        update: {

            write: function() {

                if (!this.drag || !uikitUtil.parent(this.placeholder)) {
                    return;
                }

                var ref = this;
                var ref_pos = ref.pos;
                var x = ref_pos.x;
                var y = ref_pos.y;
                var ref_origin = ref.origin;
                var offsetTop = ref_origin.offsetTop;
                var offsetLeft = ref_origin.offsetLeft;
                var placeholder = ref.placeholder;

                uikitUtil.css(this.drag, {
                    top: y - offsetTop,
                    left: x - offsetLeft
                });

                var sortable = this.getSortable(document.elementFromPoint(x, y));

                if (!sortable) {
                    return;
                }

                var items = sortable.items;

                if (items.some(uikitUtil.Transition.inProgress)) {
                    return;
                }

                var target = findTarget(items, {x: x, y: y});

                if (items.length && (!target || target === placeholder)) {
                    return;
                }

                this.touched.add(sortable);

                var previous = this.getSortable(placeholder);

                if (sortable !== previous) {
                    previous.remove(placeholder);
                }

                sortable.insert(placeholder, findInsertTarget(sortable.target, target, placeholder, x, y));

            },

            events: ['move']

        },

        methods: {

            init: function(e) {

                var target = e.target;
                var button = e.button;
                var defaultPrevented = e.defaultPrevented;
                var ref = this.items.filter(function (el) { return uikitUtil.within(target, el); });
                var placeholder = ref[0];

                if (!placeholder
                    || defaultPrevented
                    || button > 0
                    || uikitUtil.isInput(target)
                    || uikitUtil.within(target, ("." + (this.clsNoDrag)))
                    || this.handle && !uikitUtil.within(target, this.handle)
                ) {
                    return;
                }

                e.preventDefault();

                this.touched = new Set([this]);
                this.placeholder = placeholder;
                this.origin = uikitUtil.assign({target: target, index: uikitUtil.index(placeholder)}, this.pos);

                uikitUtil.on(document, uikitUtil.pointerMove, this.move);
                uikitUtil.on(document, uikitUtil.pointerUp, this.end);

                if (!this.threshold) {
                    this.start(e);
                }

            },

            start: function(e) {

                this.drag = appendDrag(this.$container, this.placeholder);
                var ref = this.placeholder.getBoundingClientRect();
                var left = ref.left;
                var top = ref.top;
                uikitUtil.assign(this.origin, {offsetLeft: this.pos.x - left, offsetTop: this.pos.y - top});

                uikitUtil.addClass(this.drag, this.clsDrag, this.clsCustom);
                uikitUtil.addClass(this.placeholder, this.clsPlaceholder);
                uikitUtil.addClass(this.items, this.clsItem);
                uikitUtil.addClass(document.documentElement, this.clsDragState);

                uikitUtil.trigger(this.$el, 'start', [this, this.placeholder]);

                trackScroll(this.pos);

                this.move(e);
            },

            move: function(e) {

                if (this.drag) {
                    this.$emit('move');
                } else if (Math.abs(this.pos.x - this.origin.x) > this.threshold || Math.abs(this.pos.y - this.origin.y) > this.threshold) {
                    this.start(e);
                }

            },

            end: function() {
                var this$1 = this;


                uikitUtil.off(document, uikitUtil.pointerMove, this.move);
                uikitUtil.off(document, uikitUtil.pointerUp, this.end);
                uikitUtil.off(window, 'scroll', this.scroll);

                if (!this.drag) {
                    return;
                }

                untrackScroll();

                var sortable = this.getSortable(this.placeholder);

                if (this === sortable) {
                    if (this.origin.index !== uikitUtil.index(this.placeholder)) {
                        uikitUtil.trigger(this.$el, 'moved', [this, this.placeholder]);
                    }
                } else {
                    uikitUtil.trigger(sortable.$el, 'added', [sortable, this.placeholder]);
                    uikitUtil.trigger(this.$el, 'removed', [this, this.placeholder]);
                }

                uikitUtil.trigger(this.$el, 'stop', [this, this.placeholder]);

                uikitUtil.remove(this.drag);
                this.drag = null;

                this.touched.forEach(function (ref) {
                        var clsPlaceholder = ref.clsPlaceholder;
                        var clsItem = ref.clsItem;

                        return this$1.touched.forEach(function (sortable) { return uikitUtil.removeClass(sortable.items, clsPlaceholder, clsItem); }
                    );
                }
                );
                this.touched = null;
                uikitUtil.removeClass(document.documentElement, this.clsDragState);

            },

            insert: function(element, target) {
                var this$1 = this;


                if (target && (element === target || element === target.previousElementSibling)) {
                    return;
                }

                uikitUtil.addClass(this.items, this.clsItem);

                var insert = function () { return target
                    ? uikitUtil.before(target, element)
                    : uikitUtil.append(this$1.target, element); };

                if (this.animation) {
                    this.animate(insert);
                } else {
                    insert();
                }

            },

            remove: function(element) {

                if (!uikitUtil.within(element, this.target)) {
                    return;
                }

                if (this.animation) {
                    this.animate(function () { return uikitUtil.remove(element); });
                } else {
                    uikitUtil.remove(element);
                }

            },

            getSortable: function(element) {
                do {
                    var sortable = this.$getComponent(element, 'sortable');

                    if (sortable && (sortable === this || this.group !== false && sortable.group === this.group)) {
                        return sortable;
                    }
                } while ((element = uikitUtil.parent(element)));
            }

        }

    };

    var trackTimer;
    function trackScroll(pos) {

        var last = Date.now();
        trackTimer = setInterval(function () {

            var x = pos.x;
            var y = pos.y;
            y += window.pageYOffset;

            var dist = (Date.now() - last) * .3;
            last = Date.now();

            uikitUtil.scrollParents(document.elementFromPoint(x, pos.y)).reverse().some(function (scrollEl) {

                var scroll = scrollEl.scrollTop;
                var scrollHeight = scrollEl.scrollHeight;

                var ref = uikitUtil.offset(uikitUtil.getViewport(scrollEl));
                var top = ref.top;
                var bottom = ref.bottom;
                var height = ref.height;

                if (top < y && top + 35 > y) {
                    scroll -= dist;
                } else if (bottom > y && bottom - 35 < y) {
                    scroll += dist;
                } else {
                    return;
                }

                if (scroll > 0 && scroll < scrollHeight - height) {
                    uikitUtil.scrollTop(scrollEl, scroll);
                    return true;
                }

            });

        }, 15);

    }

    function untrackScroll() {
        clearInterval(trackTimer);
    }

    function appendDrag(container, element) {
        var clone = uikitUtil.append(container, element.outerHTML.replace(/(^<)(?:li|tr)|(?:li|tr)(\/>$)/g, '$1div$2'));

        uikitUtil.css(clone, 'margin', '0', 'important');
        uikitUtil.css(clone, uikitUtil.assign({
            boxSizing: 'border-box',
            width: element.offsetWidth,
            height: element.offsetHeight
        }, uikitUtil.css(element, ['paddingLeft', 'paddingRight', 'paddingTop', 'paddingBottom'])));

        uikitUtil.height(clone.firstElementChild, uikitUtil.height(element.firstElementChild));

        return clone;
    }

    function findTarget(items, point) {
        return items[uikitUtil.findIndex(items, function (item) { return uikitUtil.pointInRect(point, item.getBoundingClientRect()); })];
    }

    function findInsertTarget(list, target, placeholder, x, y) {

        var items = uikitUtil.children(list);

        if (!items.length) {
            return;
        }

        var single = items.length === 1;

        if (single) {
            uikitUtil.append(list, placeholder);
        }

        var horizontal = isHorizontal(uikitUtil.children(list));

        if (single) {
            uikitUtil.remove(placeholder);
        }

        var rect = target.getBoundingClientRect();
        if (!horizontal) {
            return y < rect.top + rect.height / 2
                ? target
                : target.nextElementSibling;
        }

        var placeholderRect = placeholder.getBoundingClientRect();
        var sameLine = intersectLine(
            [rect.top, rect.bottom],
            [placeholderRect.top, placeholderRect.bottom]
        );
        return sameLine && x > rect.left + rect.width / 2 || !sameLine && placeholderRect.top < rect.top
            ? target.nextElementSibling
            : target;
    }

    function isHorizontal(items) {
        return items.some(function (el, i) {
            var rectA = el.getBoundingClientRect();
            return items.slice(i + 1).some(function (el) {
                var rectB = el.getBoundingClientRect();
                return !intersectLine([rectA.left, rectA.right], [rectB.left, rectB.right]);
            });
        });
    }

    function intersectLine(lineA, lineB) {
        return lineA[1] > lineB[0] && lineB[1] > lineA[0];
    }

    if (typeof window !== 'undefined' && window.UIkit) {
        window.UIkit.component('sortable', Component);
    }

    return Component;

})));
