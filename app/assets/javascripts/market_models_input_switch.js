$(document).on("page:change", function(){
  function tariffTypeField(switchEl) {
    return switchEl.parents('tr').find('.tariff-type [name=tariff_type]');
  }

  $("td.editable.input-switch ul.dropdown-menu li a").on("click", function(event){
    var spanClass = $(this).find("span").attr("class");
    var cell = $(this).parents("td");
    var buttonGlyph = cell.find("button.dropdown-toggle span.glyphicon");

    buttonGlyph.removeClass().addClass(spanClass);

    cell.find(".curve-tariff, .fixed-tariff").hide();
    cell.find("." + $(this).data('type') + "-tariff").show();

    tariffTypeField($(this)).val($(this).data('type'));

    window.currentMarketTable.updateTable();

    event.preventDefault();
  });

  $("td.editable.input-switch").each(function(){
    var inputPrice = $(this).data('price'),
        tariffType = tariffTypeField($(this)).val();

    if(tariffType === "curve"){
      $(this).find("button.dropdown-toggle span.glyphicon")
        .removeClass("glyphicon-euro")
        .addClass("glyphicon-signal");

      $(this).find(".curve-tariff, .fixed-tariff").toggle();
      $(this).find(".curve-tariff select").val(inputPrice);
    } else {
      $(this).find("input").val(inputPrice);
    }
  });
});
