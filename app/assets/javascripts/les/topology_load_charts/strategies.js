/*global Ajax,StrategyHelper,Poller*/

var Strategies = (function () {
    'use strict';

    var savedStrategies, changedStrategy,
        sliderSettings = {
            focus: true,
            formatter: function (value) {
                return value + "%";
            }
        },
        multiSelectSettings = {
            buttonText: function (options) {
                var text = 'Customise technology behaviour';

                if (options.length) {
                    text = text + ' (' + options.length + ' selected)';
                }

                return text;
            },
            dropRight: true
        };

    function showSlider() {
        var sliderWrapper = $(this).parents('a').find(".slider-wrapper");

        sliderWrapper.toggleClass("hidden", !$(this).is(":checked"));
    }

    function buildMultiSelect() {
        var multiSelect = $("select.multi-select");
        multiSelect.multiselect(multiSelectSettings);

        return multiSelect;
    }

    function getSelectedItems() {
        var selected = [],
            strategy;

        for (strategy in savedStrategies) {
            if (savedStrategies[strategy]) {
                selected.push(strategy);
            }
        }
        return selected;
    }

    function saveSelectedStrategies(strategies) {
        Ajax.json(
            window.currentTree.strategiesUrl,
            { strategies: strategies }
        );
    }

    function toggleStrategies(appliedStrategies) {
        // When somebody blanks the strategies
        if (changedStrategy && !StrategyHelper.anyStrategies()) {
            saveSelectedStrategies.call(this, appliedStrategies);
            window.currentTree.treeGraph.clearStrategies().reload();
        // When somebody changes the strategies but not blank
        } else if (changedStrategy) {
            saveSelectedStrategies.call(this, appliedStrategies);
            window.currentTree.updateStrategies();
        }
    }

    function updateStrategies(appliedStrategies) {
        $(".load-strategies li:not(.disabled) input[type=checkbox]").each(function () {
            appliedStrategies[$(this).val()] = $(this).is(":checked");
        });

        $(".save_strategies.hidden").text(JSON.stringify(appliedStrategies));
        toggleStrategies.call(this, appliedStrategies);
    }

    function setChangedStrategy() {
        var appliedStrategies = StrategyHelper.getStrategies();

        changedStrategy = false;

        $(".load-strategies li:not(.disabled) input[type=checkbox]").each(function () {
            if (appliedStrategies[$(this).val()] !== $(this).is(":checked")) {
                changedStrategy = true;
                return false;
            }
        });

        updateStrategies.call(this, appliedStrategies);
    }

    function setStrategies() {
        var multiSelect = buildMultiSelect(),
            cappingInput = $("input[type=checkbox][value=capping_solar_pv]");

        savedStrategies = JSON.parse($(".save_strategies").text());

        multiSelect.multiselect('select', getSelectedItems());

        cappingInput.parents('a').append($(".slider-wrapper.hidden"));
        cappingInput.on("change", showSlider);

        showSlider.call(cappingInput);

        $("#solar_pv_capping").slider(sliderSettings)
            .slider('setValue', (savedStrategies.capping_fraction || 1) * 100);
    }

    function Strategies() {
        $("button.apply_strategies").on("click", setChangedStrategy.bind(this));

        setStrategies.call(this);

        return StrategyHelper.getStrategies();
    }

    return Strategies;
}());
