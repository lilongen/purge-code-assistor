cpa = {
	uiElementsEventInit: function() {
		var jqAllUl = null;
		var jqMethodHasReferer = null;
		var jqMethodNoReferer = null;
		var jqMinusPlus = $(".minus,.plus");
		var allExpanded = false;
		var operateAllText = {
			expandAll: "Expand all",
			collapseAll: "Collapse all"
		};
		
		var jqOperateAll = $(".operateAll");
		jqOperateAll.html(operateAllText.expandAll).click(function() {
			if (!jqAllUl) {
				jqAllUl = $(".info ul")
			}
			
			if (allExpanded) {
				jqAllUl.hide();
				jqMinusPlus.removeClass("plus minus").addClass("plus");
			} else {
				jqAllUl.show();
				jqMinusPlus.removeClass("plus minus").addClass("minus");
			}
			allExpanded = !allExpanded;
			jqOperateAll.html(operateAllText[(allExpanded ? 'collapseAll' : 'expandAll')]);
		});
		
		jqMinusPlus.click(function() {
			var jqThis = jQuery(this);
			var childUL = jqThis.parent().children("ul");
			if (!childUL.length) {
				return;
			}
			if (childUL.css('display') == 'none') {
				childUL.show();
				jqThis.removeClass("plus minus").addClass("minus");
			} else {
				childUL.hide();	
				jqThis.removeClass("plus minus").addClass("plus");
			}
			
		});
		
		$("#onlyShowUnusedMethods").click(function() {
			if (!jqMethodHasReferer) {
				jqMethodHasReferer = $("li.method").not(".noReferer");
			}
			if ($(this).attr("checked") == "checked") {
				jqMethodHasReferer.hide();
			} else {
				jqMethodHasReferer.show();
			}
		});
		
		$("#onlyShowUsedMethods").click(function() {
			if (!jqMethodNoReferer) {
				jqMethodNoReferer = $("li.method.noReferer");
			}
			if ($(this).attr("checked") == "checked") {
				jqMethodNoReferer.hide();
			} else {
				jqMethodNoReferer.show();
			}
		});			
	}	
};

