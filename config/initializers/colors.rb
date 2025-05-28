COLORS = ENV.fetch('COLORS', 'Red,Orange,Yellow,Green,Blue,Purple,Pink,White,Black,Gray')
             .split(',')
             .map(&:strip)
             .freeze
