module interpret.stack_frame;

import dasm.code_obj;
import dasm.instructions;
import interpret.dyn_obj;

class StackFrame
{
  CodeObject code;
  DynObject[] locals;
  uint pc;

  this(CodeObject co)
  {
    code = co;
    pc = 0;
  }

  Instruction fetchInstr()
  {
    return code.inst[pc++];
  }
}
