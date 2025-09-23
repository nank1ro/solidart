import 'package:solidart/solidart.dart';

import 'core/solidart_widget.dart';
import 'hooks/use_effect.dart';

@Deprecated('useSolidartEffect is deprecated. Use useEffect instead.')
const useSolidartEffect = useEffect;

@Deprecated(
  'You can use Solidart\'s Signal/Computed directly; no additional wrapper is needed.',
)
T useExistingSignal<T extends ReadSignal>(T existing) => existing;

@Deprecated('Use SolidartWidget instead')
typedef HookWidget = SolidartWidget;
