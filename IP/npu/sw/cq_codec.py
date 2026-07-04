# GENERATED from command_descriptor_v0_1.yaml - DO NOT EDIT

W0_RSVD_MASK = 0xFF008000
OPCODES = {'MAT_CFG': 1, 'MAT_LOAD_W': 2, 'MAT_OP': 3, 'MAT_RESCALE': 4, 'MAT_STORE': 5, 'MAT_ACC_CLR': 6, 'MAT_FENCE': 7}
OPCODE_NAMES = {v: k for k, v in OPCODES.items()}
ERR_CAUSES = {'BAD_OPCODE': 1, 'RSVD_VIOLATION': 2, 'RING_OVERRUN': 3, 'ENGINE_NOT_READY': 4, 'DMA_FAULT': 5, 'DESC_ALIGN': 6, 'MAT_PARAM': 7, 'ABORTED': 8, 'CORE_TRAP_FLAG': 2147483648}
CSR_OFFSETS = {'CQ_RING_BASE': 64, 'CQ_RING_SIZE': 68, 'CQ_HEAD': 72, 'CQ_TAIL': 76, 'CQ_CTRL': 80, 'CQ_STATUS': 84, 'ERR_CAUSE': 88, 'CQ_EVENT': 92, 'MAT_A_ADDR': 96, 'MAT_B_ADDR': 100, 'MAT_CTRL': 104, 'MAT_MULT': 108, 'MAT_RSP': 112, 'MAT_CLAMP': 116, 'MAT_OUT_BASE': 120, 'MAT_STATUS': 124, 'ERR_PC': 128}

ERR_BAD_OPCODE = 1
ERR_RSVD_VIOLATION = 2
ERR_RING_OVERRUN = 3
ERR_ENGINE_NOT_READY = 4
ERR_DMA_FAULT = 5
ERR_DESC_ALIGN = 6
ERR_MAT_PARAM = 7
ERR_ABORTED = 8
ERR_CORE_TRAP_FLAG = 2147483648

def _op_value(op):
    if isinstance(op, str):
        key = op.upper()
        if key.startswith('CQ_OP_'):
            key = key[6:]
        if key not in OPCODES:
            raise ValueError('bad opcode %r' % (op,))
        return OPCODES[key]
    if op not in OPCODE_NAMES:
        raise ValueError('bad opcode %r' % (op,))
    return op

def _w0(op, fields):
    w0 = _op_value(op)
    w0 |= (fields.get('dtype', 0) & 0x3) << 6
    w0 |= (fields.get('acc', 0) & 0xF) << 8
    w0 |= (1 if fields.get('irq', 0) else 0) << 12
    w0 |= (1 if fields.get('fence', 0) else 0) << 13
    w0 |= (1 if fields.get('last', 0) else 0) << 14
    w0 |= (fields.get('rpt', 0) & 0xFF) << 16
    return w0 & 0xFFFFFFFF

def encode(op, **fields):
    opv = _op_value(op)
    w0 = _w0(opv, fields)
    if opv == OPCODES['MAT_CFG']:
        return [w0, ((fields.get('m', 0) & 0xFFFF) << 16) | (fields.get('n', 0) & 0xFFFF), fields.get('k', 0) & 0xFFFFFFFF, fields.get('tile_flags', 0) & 0xFFFFFFFF]
    if opv == OPCODES['MAT_LOAD_W']:
        return [w0, fields.get('src_addr', 0) & 0xFFFFFFFF, fields.get('stride', 0) & 0xFFFFFFFF, ((fields.get('rows', 0) & 0xFF) << 8) | (fields.get('cols', 0) & 0xFF)]
    if opv == OPCODES['MAT_OP']:
        return [w0, fields.get('a_addr', 0) & 0xFFFFFFFF, fields.get('b_addr', 0) & 0xFFFFFFFF, ((fields.get('acc_r', 0) & 0xF) << 4) | (fields.get('acc_c', 0) & 0xF)]
    if opv == OPCODES['MAT_RESCALE']:
        return [w0, fields.get('multiplier_q31', 0) & 0xFFFFFFFF, ((fields.get('out_zp', 0) & 0xFF) << 8) | (fields.get('shift', 0) & 0xFF), ((fields.get('clamp_max', 0) & 0xFF) << 8) | (fields.get('clamp_min', 0) & 0xFF)]
    if opv == OPCODES['MAT_STORE']:
        return [w0, fields.get('dst_addr', 0) & 0xFFFFFFFF, fields.get('stride', 0) & 0xFFFFFFFF, ((fields.get('rows', 0) & 0xFF) << 8) | (fields.get('cols', 0) & 0xFF)]
    if opv == OPCODES['MAT_ACC_CLR']:
        return [w0, fields.get('acc_mask', 0) & 0xFFFFFFFF, fields.get('bias_tcm_byte', 0) & 0xFFFFFFFF, 0]
    if opv == OPCODES['MAT_FENCE']:
        return [w0, 0, 0, 0]
    raise ValueError('bad opcode %r' % (op,))

def decode(words):
    if len(words) != 4:
        raise ValueError('descriptor must have 4 words')
    w0, w1, w2, w3 = [x & 0xFFFFFFFF for x in words]
    if w0 & W0_RSVD_MASK:
        raise ValueError('reserved W0 bits set')
    opv = w0 & 0x3F
    if opv not in OPCODE_NAMES:
        raise ValueError('bad opcode 0x%02x' % opv)
    d = {'op': OPCODE_NAMES[opv], 'opcode': opv, 'dtype': (w0 >> 6) & 0x3, 'acc': (w0 >> 8) & 0xF, 'irq': (w0 >> 12) & 1, 'fence': (w0 >> 13) & 1, 'last': (w0 >> 14) & 1, 'rpt': (w0 >> 16) & 0xFF}
    if opv == OPCODES['MAT_CFG']:
        d.update({'m': (w1 >> 16) & 0xFFFF, 'n': w1 & 0xFFFF, 'k': w2, 'tile_flags': w3})
    elif opv == OPCODES['MAT_LOAD_W']:
        d.update({'src_addr': w1, 'stride': w2, 'rows': (w3 >> 8) & 0xFF, 'cols': w3 & 0xFF})
    elif opv == OPCODES['MAT_OP']:
        d.update({'a_addr': w1, 'b_addr': w2, 'acc_r': (w3 >> 4) & 0xF, 'acc_c': w3 & 0xF})
    elif opv == OPCODES['MAT_RESCALE']:
        d.update({'multiplier_q31': w1, 'out_zp': (w2 >> 8) & 0xFF, 'shift': w2 & 0xFF, 'clamp_max': (w3 >> 8) & 0xFF, 'clamp_min': w3 & 0xFF})
    elif opv == OPCODES['MAT_STORE']:
        d.update({'dst_addr': w1, 'stride': w2, 'rows': (w3 >> 8) & 0xFF, 'cols': w3 & 0xFF})
    elif opv == OPCODES['MAT_ACC_CLR']:
        d.update({'acc_mask': w1, 'bias_tcm_byte': w2})
    return d

def _self_test():
    samples = {
        'MAT_CFG': dict(m=8, n=8, k=16, tile_flags=3, last=1),
        'MAT_LOAD_W': dict(src_addr=0x800, stride=0, rows=4, cols=4),
        'MAT_OP': dict(a_addr=0x10, b_addr=0x20, acc_r=1, acc_c=2),
        'MAT_RESCALE': dict(multiplier_q31=0x40000000, out_zp=1, shift=7, clamp_max=127, clamp_min=128),
        'MAT_STORE': dict(dst_addr=0x1000, stride=0, rows=4, cols=4, irq=1),
        'MAT_ACC_CLR': dict(acc_mask=0x5, bias_tcm_byte=0x600),
        'MAT_FENCE': dict(fence=1),
    }
    for name, fields in samples.items():
        words = encode(name, **fields)
        assert decode(words)['op'] == name
    try:
        decode([0x00008001, 0, 0, 0])
    except ValueError:
        pass
    else:
        raise AssertionError('reserved violation was accepted')
    print('cq_codec self-test PASS')

if __name__ == '__main__':
    _self_test()
