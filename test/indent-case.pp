case true {
  'one': { }
  default: { }
}

case true {
  'one': { }
  'two': { }
  default: { }
}

case true {
  'one', 'two': { }
  'three': { }
  default: { }
}

case true {
  /(one|two)/: { }
  /(three|four)/: { }
  default: { }
}
