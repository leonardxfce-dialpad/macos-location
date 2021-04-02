{
  'targets': [
    {
      'target_name': 'bindings',
      'sources': [
        'src/LocationManager.mm',
        'src/CLLocationBindings.mm'
      ],
      "include_dirs" : [
        "<!(node -e \"require('nan')\")"
      ],
      'link_settings': {
        'libraries': [
          'CoreLocation.framework'
        ]
      }
    }
  ]
}
