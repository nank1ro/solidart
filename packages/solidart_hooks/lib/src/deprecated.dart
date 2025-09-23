import 'package:solidart/solidart.dart';

import 'core/solidart_widget.dart';
import 'hooks/use_effect.dart';

@Deprecated('useSolidartEffect is deprecated. Use useEffect instead.')
const useSolidartEffect = useEffect;

@Deprecated(
  'Now, you can directly use Solidart\'s Signal/Computed, No need for additional packaging',
)
T useExistingSignal<T extends ReadSignal>(T existing) => existing;

@Deprecated('Use SolidartWidget instead')
typedef HookWidget = SolidartWidget;
