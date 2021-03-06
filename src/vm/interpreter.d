module vm.interpreter;

import std.stdio;

import common.common;
import hlasm.code_obj;
import hlasm.instructions;
import vm.dyn_obj;
import vm.state;

enum LOUD = false;

void interpretCode(ref State state, bool silent)
{
  Instruction inst;

  void binOp(string name)() {
    auto obj_b = state.getRegister(inst.iABC.b);
    auto obj_c = state.getRegister(inst.iABC.c);
    auto func_obj = obj_b.Dyn_get(name);
    auto obj_a = func_obj.Dyn_call2(obj_b, obj_c);
    state.setRegister(inst.iABC.a, obj_a);
  }


 EXECLOOP:
  while(true) {
    inst = state.fetchInstr();
    if(LOUD) writeln(inst.toString());

    final switch(inst.opcode)
    {
      case IOpcode.LITERAL:
        auto obj = state.getLiteralObj(inst.iABx.bx);
        state.setRegister(inst.iABx.a, obj);
        break;

      case IOpcode.LOADGLOBAL:
        auto obj = state.getGlobal(inst.iABx.bx);
        state.setRegister(inst.iABx.a, obj);
        break;

      case IOpcode.STOREGLOBAL:
        auto obj = state.getRegister(inst.iABx.a);
        state.setGlobal(inst.iABx.bx, obj);
        break;

      case IOpcode.MOVE:
        auto obj = state.getRegister(inst.iAB.b);
        state.setRegister(inst.iAB.a, obj);
        break;

      case IOpcode.RET:
        state.ret = state.getRegister(inst.iA.a);
        break EXECLOOP;  // for now RET just exits

      case IOpcode.NEWOBJECT:
        state.setRegister(inst.iA.a, DynObjectBuiltin.create!("object"));
        break;

      case IOpcode.SETSELF:
        state.self = state.getRegister(inst.iAB.a);
        break;

      case IOpcode.GET:
        auto obj = state.selfGet(inst.iABx.bx);
        state.setRegister(inst.iABx.a, obj);
        break;

      case IOpcode.SET:
        auto obj = state.getRegister(inst.iABx.a);
        state.selfSet(inst.iABx.bx, obj);
        break;

      case IOpcode.CALL:
        DynObject[] args;
        uint arg_num = inst.iABC.b+1;
        uint arg_end = inst.iABC.c;
        foreach(i; arg_num..arg_end+1)
          args ~= state.getRegister(i);

        //writeln(args);
        auto objB = state.getRegister(inst.iABC.b);
        auto obj = objB.vtable.call(args, objB);
        state.setRegister(inst.iABC.a, obj);
        break;

      case IOpcode.TEST:
        bool t  = state.getRegister(inst.iABx.a).Dyn_truthiness;
        bool tl = state.getLiteral(inst.iABx.bx).truthiness;
        if(t != tl) state.pc += 1;
        break;

      case IOpcode.JMPTRUE:
        if(state.getRegister(inst.iAsBx.a).Dyn_truthiness)
          state.pc += inst.iAsBx.sbx.sBx18_to_int;
        break;

      case IOpcode.JMPFALSE:
        if(!state.getRegister(inst.iAsBx.a).Dyn_truthiness)
          state.pc += inst.iAsBx.sbx.sBx18_to_int;
        break;

      case IOpcode.JMP:
        int offset = inst.isBx.sbx.sBx26_to_int;
        state.pc += offset;
        break;

      // binary operations
      case IOpcode.ADD:   binOp!"__op_add";   break;
      case IOpcode.SUB:   binOp!"__op_sub";   break;
      case IOpcode.MUL:   binOp!"__op_mul";   break;
      case IOpcode.DIV:   binOp!"__op_div";   break;

    }
  }
}
