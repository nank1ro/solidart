import 'package:solidart/solidart.dart';

import '../solidart_hooks.dart';

@Deprecated('useSolidartEffect is deprecated. Use useEffect instead.')
const useSolidartEffect = useEffect;

@Deprecated(
  'Now, you can directly use Solidart\'s Signal/Computed, No need for additional packaging',
)
T useExistingSignal<T extends ReadSignal>(T existing) => existing;

@Deprecated('Use SolidartWidget instead')
typedef HookWidget = SolidartWidget;
