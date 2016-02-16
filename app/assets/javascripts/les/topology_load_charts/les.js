/*globals StrategyHelper*/
var Les = (function () {
    'use strict';

    Les.prototype = {
        nodeData: function (resolution) {
            this.data = { calculation: {} };
            this.data.type = ($.isEmptyObject(this.strategies) ? 'basic' :  'features');

            if (resolution) {
                this.data.calculation.resolution = resolution;
            }

            if (resolution === 'high') {
                this.data.calculation.nodes = LoadChartHelper.nodes;
            }

            if (this.strategies) {
                this.data.calculation.strategies = StrategyHelper.getStrategies();
            }

            return this.data;
        },

        anyStrategies: function () {
            return (this.data.calculation.strategies === undefined ||
                    (this.data.calculation.strategies && StrategyHelper.anyStrategies()));
        }
    };

    function Les(strategies) {
        this.strategies = strategies;
    }

    return Les;
}());