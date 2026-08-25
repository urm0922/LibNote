document.addEventListener("turbo:load", () => {
  /*Railsの画面表示が終わったら処理を始める*/

  const form = document.getElementById("post_inquiry")
  if (!form) return
  /*「post_inquiry」という投稿フォームを探す
   見つからなければ何もしない*/

  const fileField = form.querySelector(
    'input[type="file"][name="inquiry[images][]"]'
  )
  const previews = document.getElementById("previews")
  /*投稿フォーム内から画像選択欄を探す
 「previews」という画像表示欄も探す*/

  if (!fileField || !previews) return
  /*どちらかが見つからなければ何もしない*/

  let selectedFiles = []
  /*現在選択されている画像を配列で管理する*/

  fileField.addEventListener("change", () => {
    selectedFiles = Array.from(fileField.files)
    renderPreviews()
  })

  // 選択中の画像をプレビュー表示する
  function renderPreviews() {
    previews.replaceChildren()

    selectedFiles.forEach((file, index) => {
      const wrapper = document.createElement("div")
      const image = document.createElement("img")
      const removeButton = document.createElement("button")
      const imageUrl = URL.createObjectURL(file)

      image.className = "preview-image"
      image.alt = "選択した画像のプレビュー"

       // 画像の読み込み後、一時URLを解放する
      image.addEventListener(
        "load",
        () => URL.revokeObjectURL(imageUrl),
        { once: true }
      )

      image.src = imageUrl

      removeButton.type = "button"
      removeButton.textContent = "この画像を選択から削除"

      removeButton.addEventListener("click", () => {
        // 配列から選択した画像を削除する
        selectedFiles.splice(index, 1)

        // file inputの中身も更新する
        const transfer = new DataTransfer()
        selectedFiles.forEach((selectedFile) => {
          transfer.items.add(selectedFile)
        })

        fileField.files = transfer.files
        renderPreviews()
      })

      wrapper.appendChild(image)
      wrapper.appendChild(removeButton)
      previews.appendChild(wrapper)
    })
  }
})
