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


  fileField.addEventListener("change", () => {
    previews.replaceChildren()
  /*画像選択欄の内容が変更されたら、以前のプレビュー画像をすべて消す*/

    Array.from(fileField.files).forEach((file) => {
      if (!file.type.startsWith("image/")) return
    /*選択されたファイルをひとつずつ確認するが、画像ファイルでなければ、そのファイルは無視する*/

      const image = document.createElement("img")
      /*画像表示用のimg要素を作る*/
      image.src = URL.createObjectURL(file)
      /*選択ファイルの一時URLを作ってsrcに設定する*/
      image.className = "preview-image"
      /*CSSクラスの設定*/
      image.alt = "選択した画像のプレビュー"
      /*代替テキスト*/
      previews.appendChild(image)
      /*完成したimg要素をプレビュー欄に追加する*/
    })
  })
})