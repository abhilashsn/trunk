
    jQuery.ui.plugin.add("resizable", "alsoResizeReverse", {

        start: function(event, ui) {

            var self = jQuery(this).data("resizable"), o = self.options;

            var _store = function(exp) {
                jQuery(exp).each(function() {
                    jQuery(this).data("resizable-alsoresize-reverse", {
                        width: parseInt(jQuery(this).width(), 10), height: parseInt(jQuery(this).height(), 10),
                        left: parseInt(jQuery(this).css('left'), 10), top: parseInt(jQuery(this).css('top'), 10)
                    });
                });
            };

            if (typeof(o.alsoResizeReverse) == 'object' && !o.alsoResizeReverse.parentNode) {
                if (o.alsoResizeReverse.length) {
                    o.alsoResize = o.alsoResizeReverse[0];
                    _store(o.alsoResizeReverse);
                }
                else {
                    jQuery.each(o.alsoResizeReverse, function(exp, c) {
                        _store(exp);
                    });
                }
            } else {
                _store(o.alsoResizeReverse);
            }
        },

        resize: function(event, ui) {
            var self = jQuery(this).data("resizable"), o = self.options, os = self.originalSize, op = self.originalPosition;

            var delta = {
                height: (self.size.height - os.height) || 0, width: (self.size.width - os.width) || 0,
                top: (self.position.top - op.top) || 0, left: (self.position.left - op.left) || 0
            },

                    _alsoResizeReverse = function(exp, c) {
                        jQuery(exp).each(function() {
                            var el = jQuery(this), start = jQuery(this).data("resizable-alsoresize-reverse"), style = {}, css = c && c.length ? c : ['width', 'height', 'top', 'left'];

                            jQuery.each(css || ['width', 'height', 'top', 'left'], function(i, prop) {
                                var sum = (start[prop] || 0) - (delta[prop] || 0);
                                if (sum && sum >= 0)
                                    style[prop] = sum || null;
                            });

                            //Opera fixing relative position
                            if (/relative/.test(el.css('position')) && jQuery.browser.opera) {
                                self._revertToRelativePosition = true;
                                el.css({ position: 'absolute', top: 'auto', left: 'auto' });
                            }

                            el.css(style);
                        });
                    };

            if (typeof(o.alsoResizeReverse) == 'object' && !o.alsoResizeReverse.nodeType) {
                jQuery.each(o.alsoResizeReverse, function(exp, c) {
                    _alsoResizeReverse(exp, c);
                });
            } else {
                _alsoResizeReverse(o.alsoResizeReverse);
            }
        },

        stop: function(event, ui) {
            var self = jQuery(this).data("resizable");

            //Opera fixing relative position
            if (self._revertToRelativePosition && jQuery.browser.opera) {
                self._revertToRelativePosition = false;
                el.css({ position: 'relative' });
            }

            jQuery(this).removeData("resizable-alsoresize-reverse");
        }
    });
