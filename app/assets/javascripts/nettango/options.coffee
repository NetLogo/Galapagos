netLogoOptionInfo = {
  commandCenterTab: {
    label: "Hide command center tab"
    checkedCssBuild:  'div.netlogo-tab-area > label:nth-of-type(1) { background: #eee; }'
    checkedCssExport: 'div.netlogo-tab-area > label:nth-of-type(1) { display: none; }'
  }
  codeTab: {
    label: "Hide code tab"
    checkedCssBuild:  'div.netlogo-tab-area > label:nth-of-type(2) { background: #eee; }'
    checkedCssExport: 'div.netlogo-tab-area > label:nth-of-type(2) { display: none; }'
  }
  infoTab: {
    label: "Hide info tab"
    checkedCssBuild:  'div.netlogo-tab-area > label:nth-of-type(3) { background: #eee; }'
    checkedCssExport: 'div.netlogo-tab-area > label:nth-of-type(3) { display: none; }'
  }
  speedBar: {
    label: "Hide model speed bar"
    checkedCssBuild:  '.netlogo-speed-slider { background: #eee; }'
    checkedCssExport: '.netlogo-speed-slider { display: none; }'
  }
  fileButtons: {
    label: "Hide file and export buttons"
    checkedCssBuild:  '.netlogo-export-wrapper { background: #eee; }'
    checkedCssExport: '.netlogo-export-wrapper { display: none; }'
  }
  authoring: {
    label: "Hide authoring unlock toggle"
    checkedCssBuild:  '#authoring-lock { background: #eee; }'
    checkedCssExport: '#authoring-lock { display: none; }'
  }
  tabsPosition: {
    label: "Hide commands and code position toggle"
    checkedCssBuild:  '#tabs-position { background: #eee; }'
    checkedCssExport: '#tabs-position { display: none; }'
  }
  poweredBy: {
    label: "Hide 'Powered by NetLogo' link"
    checkedCssBuild:  '.netlogo-powered-by { background: #eee; }'
    checkedCssExport: '.netlogo-powered-by { display: none; }'
  }
}

netTangoOptionInfo = {
  workspaceBelow: {
    label: "Show NetTango spaces below the NetLogo model"
  },
  showCode: {
    label: "Show the generated NetLogo Code below the NetTango spaces"
  }
}

netLogoOptionDefaults = {
  commandCenterTab: true
  codeTab:          true
  infoTab:          true
  speedBar:         true
  fileButtons:      true
  authoring:        true
  poweredBy:        false
}

netTangoOptionDefaults = {
  workspaceBelow: false
  showCode:       true
}

export { netLogoOptionInfo, netLogoOptionDefaults, netTangoOptionInfo, netTangoOptionDefaults }
