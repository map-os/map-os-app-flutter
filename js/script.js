
  let pixPayload = '';

  function gerarPixPayload(chave, valor, descricao) {
    const merchantName = "MAP-OS Project";
    const merchantCity = "Sao Paulo";
    const txId = Math.random().toString(36).substring(2, 12).toUpperCase();
    
    function formatSize(content) {
      return content.length.toString().padStart(2, '0');
    }
    
    let payload = '';
    
    // Payload Format Indicator
    payload += '000201';
    
    // Point of Initiation Method
    payload += '010212';
    
    // Merchant Account Information
    const pixInfo = `0014br.gov.bcb.pix01${formatSize(chave)}${chave}`;
    payload += `26${formatSize(pixInfo)}${pixInfo}`;
    
    // Merchant Category Code
    payload += '52040000';
    
    // Transaction Currency (BRL)
    payload += '5303986';
    
    // Transaction Amount
    if (valor && parseFloat(valor) > 0) {
      const valorFormatado = parseFloat(valor).toFixed(2);
      payload += `54${formatSize(valorFormatado)}${valorFormatado}`;
    }
    
    // Country Code
    payload += '5802BR';
    
    // Merchant Name
    payload += `59${formatSize(merchantName)}${merchantName}`;
    
    // Merchant City
    payload += `60${formatSize(merchantCity)}${merchantCity}`;
    
    // Additional Data Field Template
    if (descricao && descricao.trim()) {
      const desc = descricao.trim();
      const additionalData = `05${formatSize(txId)}${txId}50${formatSize(desc)}${desc}`;
      payload += `62${formatSize(additionalData)}${additionalData}`;
    } else {
      const additionalData = `05${formatSize(txId)}${txId}`;
      payload += `62${formatSize(additionalData)}${additionalData}`;
    }
    
    // CRC16
    payload += '6304';
    const crc = calculateCRC16(payload);
    payload += crc;
    
    return payload;
  }

  function calculateCRC16(str) {
    const polynomial = 0x1021;
    let crc = 0xFFFF;
    
    for (let i = 0; i < str.length; i++) {
      crc ^= (str.charCodeAt(i) << 8);
      
      for (let j = 0; j < 8; j++) {
        if (crc & 0x8000) {
          crc = ((crc << 1) ^ polynomial) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    
    return crc.toString(16).toUpperCase().padStart(4, '0');
  }

  function validarFormulario() {
    const valor = document.getElementById('valor').value.trim();
    const valorInput = document.getElementById('valor');
    const valorError = document.getElementById('valor-error');
    
    let isValid = true;
    
    // Validar valor
    if (!valor || parseFloat(valor) <= 0) {
      valorInput.classList.add('invalid');
      valorError.classList.add('show');
      isValid = false;
    } else {
      valorInput.classList.remove('invalid');
      valorError.classList.remove('show');
    }
    
    return isValid;
  }

  function gerarPix() {
    if (!validarFormulario()) {
      return;
    }

    const chave = "be015a90-8e5f-46b7-9b3d-105e79b53f34";
    const valor = document.getElementById('valor').value.trim();
    const descricao = '';

    // Gerar payload PIX
    pixPayload = gerarPixPayload(chave, valor, descricao);

    // Gerar QR Code
    const qrDiv = document.getElementById('qrcode');
    const existingCanvas = qrDiv.querySelector('canvas');
    if (existingCanvas) {
      existingCanvas.remove();
    }

    const canvas = document.createElement('canvas');
    qrDiv.appendChild(canvas);

    new QRious({
      element: canvas,
      value: pixPayload,
      size: 280,
      background: 'white',
      foreground: 'black',
      level: 'M'
    });

    // Mostrar código PIX
    document.getElementById('pixCode').textContent = pixPayload;
    
    // Mostrar seção de resultados
    document.getElementById('resultSection').classList.add('show');
    
    // Scroll suave para os resultados
    document.getElementById('resultSection').scrollIntoView({ 
      behavior: 'smooth', 
      block: 'start' 
    });

    console.log('Payload PIX gerado:', pixPayload);
  }

  function copiarCodigo() {
    if (!pixPayload) {
      alert('Por favor, gere o código PIX primeiro.');
      return;
    }

    navigator.clipboard.writeText(pixPayload).then(() => {
      mostrarSucesso();
    }).catch(() => {
      // Fallback para navegadores mais antigos
      const textArea = document.createElement('textarea');
      textArea.value = pixPayload;
      textArea.style.position = 'fixed';
      textArea.style.opacity = '0';
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand('copy');
      document.body.removeChild(textArea);
      mostrarSucesso();
    });
  }

  function mostrarSucesso() {
    const successMsg = document.getElementById('successMessage');
    successMsg.classList.add('show');
    setTimeout(() => {
      successMsg.classList.remove('show');
    }, 3000);
  }

  function limparFormulario() {
    document.getElementById('valor').value = '';
    document.getElementById('descricao').value = '';
    document.getElementById('valor').classList.remove('invalid');
    document.getElementById('valor-error').classList.remove('show');
    document.getElementById('resultSection').classList.remove('show');
    pixPayload = '';
  }

  // Event listeners
  document.addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
      gerarPix();
    }
  });

  // Formatação automática do valor
  document.getElementById('valor').addEventListener('input', function(e) {
    let value = e.target.value;
    value = value.replace(/[^\d.]/g, '');
    const parts = value.split('.');
    if (parts.length > 2) {
      value = parts[0] + '.' + parts.slice(1).join('');
    }
    e.target.value = value;
    
    // Remove validação visual ao digitar
    if (value && parseFloat(value) > 0) {
      e.target.classList.remove('invalid');
      document.getElementById('valor-error').classList.remove('show');
    }
  });

  // Placeholder dinâmico
  document.getElementById('valor').addEventListener('focus', function(e) {
    if (!e.target.value) {
      e.target.placeholder = '10.00';
    }
  });

  document.getElementById('valor').addEventListener('blur', function(e) {
    if (!e.target.value) {
      e.target.placeholder = '0,00';
    }
  });
