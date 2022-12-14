# NW Loot Tables
# Server File

# TODO: update to single-file framework with just app.R

# Libraries
library(shiny)
library(DT)

lt_nested <- readRDS("data/lt-nested.rds")

# Callback for creating subtables
# TODO: put this in a separate .js file and clean it up
callback <- JS(
    sprintf("var parentRows = [%s];", toString(nrow(lt_nested) - 1)),
    sprintf("var j = [%s];", toString(c(0, 1))),
    "var nrows = table.rows().count();",
    "for(let i = 0; i < nrows; ++i){",
    "  var $cellclick = table.cells(i, j).nodes().to$();",
    "  var $cellarrow = table.cell(i, 0).nodes().to$();",
    "  $cellarrow.addClass('details-control-arrow')",
    "  if(parentRows.indexOf(i) > -1){",
    "    $cellclick.css({cursor: 'pointer'});",
    "  }else{",
    "    $cellclick.removeClass('details-control');",
    "  }",
    "}",
    "",
    "// --- make the table header of the nested table --- //",
    "var formatHeader = function(d, childId){",
    "  if(d !== null){",
    "    var html = ",
    "      '<table class=\"\" ' + ",
    "      'style=\"border: none;\" id=\"' + childId + ",
    "      '\"><thead><tr>';",
    "    var data = d[d.length-1] || d.details;",
    "    for(let key in data[0]){",
    "      html += '<th>' + key + '</th>';",
    "    }",
    "    html += '</tr></thead></table>'",
    "    return html;",
    "  } else {",
    "    return '';",
    "  }",
    "};",
    "",
    "// --- row callback to style rows of child tables --- //",
    "var rowCallback = function(row, dat, displayNum, index){",
    "  $(row).css({",
    "    'background-color': 'transparent',",
    "    'line-height': '12px',",
    "    'color': '#a8a290',",
    "    'border': 'none'",
    "  });",
    "  $(row).find('td').css({'border': 'none'});",
    "};",
    "",
    "// --- header callback to style header of child tables --- //",
    "var headerCallback = function(thead, data, start, end, display){",
    "  $('th', thead).css({",
    "    'background-color': 'transparent',",
    "    'line-height': '12px',",
    "    'color': '#a8a290',",
    "    'border-bottom': '1px solid #262524'",
    "  });",
    "};",
    "",
    "// --- make the datatable --- //",
    "var formatDatatable = function(d, childId){",
    "  var data = d[d.length-1] || d.details;",
    "  var colNames = Object.keys(data[0]);",
    "  var columns = colNames.map(function(x){",
    "    return {data: x.replace(/\\./g, '\\\\\\.'), title: x};",
    "  });",
    "  var id = 'table#' + childId;",
    "  if(colNames.indexOf('details') === -1){",
    "    var subtable = $(id).DataTable({",
    "      'data': data,",
    "      'columns': columns,",
    "      'autoWidth': true,",
    "      'deferRender': true,",
    "      'info': false,",
    "      'lengthChange': false,",
    "      'ordering': data.length > 1,",
    "      'order': [],",
    "      'paging': false,",
    "      'scrollX': false,",
    "      'scrollY': false,",
    "      'searching': false,",
    "      'sortClasses': false,",
    "      'rowCallback': rowCallback,",
    "      'headerCallback': headerCallback,",
    "      'columnDefs': [{targets: 0, orderable: false, className: 'blank'}, {targets: '_all', className: 'dt-left'}]",
    "    });",
    "  } else {",
    "    var subtable = $(id).DataTable({",
    "      'data': data,",
    "      'columns': columns,",
    "      'autoWidth': true,",
    "      'deferRender': true,",
    "      'info': false,",
    "      'lengthChange': false,",
    "      'ordering': data.length > 1,",
    "      'order': [],",
    "      'paging': false,",
    "      'scrollX': false,",
    "      'scrollY': false,",
    "      'searching': false,",
    "      'sortClasses': false,",
    "      'rowCallback': rowCallback,",
    "      'headerCallback': headerCallback,",
    "      'columnDefs': [",
    "        {targets: -1, visible: false},",
    "        {targets: 0, orderable: false, className: 'details-control'},",
    "        {targets: '_all', className: 'dt-left'}",
    "      ]",
    "    }).column(0).nodes().to$().css({cursor: 'pointer'});",
    "  }",
    "};",
    "",
    "// --- display the child table on click --- //",
    "// array to store id's of already created child tables",
    "var children = [];",
    "table.on( 'search.dt', function () {",
    "  children = [];",
    "} );",
    "table.on( 'page.dt', function () {",
    "  children = [];",
    "} );",
    "$('#lt tbody').on('click', 'tr td.details-control', function(){",
    "  var tbl = $(this).closest('table'),",
    "      tblId = tbl.attr('id'),",
    "      td = $(this),",
    "      row = $(tbl).DataTable().row(td.parent()),",
    "      rowIdx = row.index();",
    "  if(row.child.isShown()){",
    "    row.child.hide();",
    "    $(this).closest('tr').find('svg').attr('data-icon', 'angle-right');",
    "  } else {",
    "    var childId = tblId + '-child-' + rowIdx;",
    "    $(this).closest('tr').find('svg').attr('data-icon', 'angle-down');",
    "    if(children.indexOf(childId) === -1){",
    "      // this child has not been created yet",
    "      children.push(childId);",
    "      row.child(formatHeader(row.data(), childId)).show();",
    "      formatDatatable(row.data(), childId, rowIdx);",
    "    }else{",
    "      // this child has already been created",
    "      row.child(true);",
    "    }",
    "  }",
    "});"
)

# Render table
shinyServer(function(input, output, session) {
    output$lt = DT::renderDT(
        lt_nested,
        callback = callback,
        rownames = FALSE,
        escape = -1,
        selection = 'none',
        options = list(
            searchDelay = 500,
            deferRender = TRUE,
            processing = FALSE,
            scrollX = TRUE,
            columnDefs = list(
                list(visible = FALSE,
                     targets = ncol(lt_nested) - 1),
                list(
                    orderable = FALSE,
                    className = "details-control",
                    targets = c(0, 1)
                ),
                list(className = "dt-left",
                     targets = "_all"),
                list(className = "details-control-arrow",
                     targets = c(0)),
                list(visible = FALSE,
                     targets = c(-2))
            )
        )
    )
})
