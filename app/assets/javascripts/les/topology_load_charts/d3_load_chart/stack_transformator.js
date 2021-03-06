var StackTransformator = (function () {
    'use strict';

    var stack = d3.layout.stack()
        .values(function(d) { return d.values; });

    StackTransformator.prototype = {
        transform: function () {
            if (this.data.length > 0) {
                var size = this.data[0].values.length;

                while(size--) {
                    var posOffset = 0,
                        negOffset = 0;

                    this.data.forEach(function(d) {
                        d = d.values[size];

                        if (d.y < 0) {
                            d.offset = negOffset;
                            negOffset += d.y;
                        }
                        else {
                            d.offset = posOffset;
                            posOffset += d.y;
                        }
                    });
                }
            }

            this.data.sort(function (a,b) {
                return a.key > b.key;
            });

            return stack(this.data);
        }
    };

    function StackTransformator(data) {
        this.data = data;
    }

    return StackTransformator;
}());
